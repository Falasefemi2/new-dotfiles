-- http.lua
-- Minimal, dependency-free HTTP client for `.http` / `.rest` files.
--
-- Why hand-rolled: rest.nvim needs LuaRocks-only modules (mimetypes, xml2lua)
-- that vim.pack cannot install, and kulala.nvim now requires a license token.
-- This speaks the IntelliJ/VS Code `.http` spec (### separators, `@var = value`
-- file variables, `{{var}}` interpolation, .env lookup) and shells out to curl.
--
-- Keymaps (only in `http` buffers):
--   <leader>Hr  run the request under the cursor
--   <leader>Hl  run the last request again

local M = {}

vim.filetype.add {
  extension = { http = 'http', rest = 'http' },
}

local ENV_FILES = { '.env', '.env.local' }
local ROOT_MARKERS = { '.git', 'package.json', 'go.mod' }

local function find_curl()
  if vim.fn.executable 'curl' == 1 then return 'curl' end
  if vim.fn.has 'win32' == 1 and vim.fn.executable 'curl.exe' == 1 then return 'curl.exe' end
  return nil
end

local function project_root(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr or 0)
  local start = name ~= '' and vim.fn.fnamemodify(name, ':p:h') or vim.fn.getcwd()
  return vim.fs.root(start, ROOT_MARKERS) or vim.fn.getcwd()
end

--- Collect KEY=VALUE pairs from the project's .env files (first wins).
local function load_env(bufnr)
  local root = project_root(bufnr)
  local vars = {}
  for _, name in ipairs(ENV_FILES) do
    local path = vim.fs.joinpath(root, name)
    if vim.fn.filereadable(path) == 1 then
      for _, line in ipairs(vim.fn.readfile(path)) do
        if line ~= '' and not line:match '^%s*#' then
          local key, value = line:match '^%s*([%w_][%w_]*)%s*=%s*(.*)$'
          if key and vars[key] == nil then
            value = vim.trim(value):gsub('^"(.*)"$', '%1'):gsub("^'(.*)'$", '%1')
            vars[key] = value
          end
        end
      end
    end
  end
  return vars
end

local function substitute(text, vars)
  return (text:gsub('{{%s*([%w_%-%.]+)%s*}}', function(key) return vars[key] or ('{{' .. key .. '}}') end))
end

--- Collect top-level `@name = value` file variables from the whole buffer.
local function collect_vars(lines, vars)
  for _, line in ipairs(lines) do
    local name, value = line:match '^%s*@([%w_%-%.]+)%s*=%s*(.-)%s*$'
    if name then vars[name] = value end
  end
end

--- Split the buffer into request blocks on lines starting with `###`.
local function request_blocks(lines)
  local result, start = {}, 1
  for i, line in ipairs(lines) do
    if line:match '^%s*###' then
      table.insert(result, { start, i - 1 })
      start = i + 1
    end
  end
  table.insert(result, { start, #lines })
  return result
end

local function block_at(blocks, lnum)
  for _, b in ipairs(blocks) do
    if lnum >= b[1] and lnum <= b[2] then return b end
  end
  return blocks[#blocks]
end

--- Parse one request block into { method, url, headers, body }.
local function parse_block(lines, block, vars)
  local method, url = 'GET', nil
  local headers, body = {}, {}
  local state = 'request'

  for i = block[1], block[2] do
    local line = lines[i]
    if state == 'request' then
      local name, value = line:match '^%s*@([%w_%-%.]+)%s*=%s*(.-)%s*$'
      if name then
        vars[name] = substitute(value, vars)
      elseif line:match '^%s*#' or line:match '^%s*//' then -- comment / request name
        -- skip
      elseif line:match '^%s*$' then -- leading blank line
        -- skip
      else
        local m, rest = line:match '^(%u+)%s+(.+)$'
        method, url = m or 'GET', rest or line
        url = vim.trim(substitute((url or ''):gsub('%s+HTTP/%d[.%d]*$', ''), vars))
        state = 'headers'
      end
    elseif state == 'headers' then
      if line:match '^%s*$' then
        state = 'body'
      else
        local key, value = line:match '^(.-):%s*(.*)$'
        if key and key ~= '' then table.insert(headers, substitute(key .. ': ' .. value, vars)) end
      end
    else
      table.insert(body, substitute(line, vars))
    end
  end

  if not url or url == '' then return nil end
  return { method = method, url = url, headers = headers, body = table.concat(body, '\n') }
end

--- Render response text in a readonly scratch split.
function M.show(lines)
  vim.cmd 'botright split'
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = 'wipe'
  vim.api.nvim_win_set_buf(0, buf)
end

local function run(bufnr, lnum)
  local curl = find_curl()
  if not curl then
    vim.notify('http: `curl` not found on PATH', vim.log.levels.ERROR)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local vars = load_env(bufnr)
  collect_vars(lines, vars)
  local req = parse_block(lines, block_at(request_blocks(lines), lnum), vars)
  if not req then
    vim.notify('http: no request found around cursor', vim.log.levels.WARN)
    return
  end

  local args = { curl, '-sS', '-i', '-L', '-X', req.method, req.url }
  for _, header in ipairs(req.headers) do
    vim.list_extend(args, { '-H', header })
  end

  local opts = { text = true, cwd = project_root(bufnr) }
  if req.body ~= '' then
    vim.list_extend(args, { '--data-binary', '@-' })
    opts.stdin = req.body .. '\n'
  end

  vim.notify(('http: %s %s'):format(req.method, req.url), vim.log.levels.INFO)
  vim.system(
    args,
    opts,
    vim.schedule_wrap(function(out)
      local text = out.stdout or ''
      if (out.stderr or '') ~= '' then text = text .. '\n' .. out.stderr end
      if text == '' then text = ('(no output; exit code %d)'):format(out.code) end
      M.show(vim.split(text, '\n', { plain = true }))
    end)
  )
end

local last_lnum = nil

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('http-keymaps', { clear = true }),
  pattern = 'http',
  callback = function(event)
    local buf = event.buf
    vim.keymap.set('n', '<leader>Hr', function()
      last_lnum = vim.api.nvim_win_get_cursor(0)[1]
      run(buf, last_lnum)
    end, { buffer = buf, desc = '[H]TTP [R]un request under cursor' })
    vim.keymap.set('n', '<leader>Hl', function()
      if not last_lnum then
        vim.notify('http: no previous request in this session', vim.log.levels.WARN)
        return
      end
      run(buf, last_lnum)
    end, { buffer = buf, desc = '[H]TTP run [L]ast request' })
  end,
})

return M
