-- node.lua
-- Node/TypeScript/JavaScript workflow helpers: a package-manager aware test
-- runner, a package.json script runner, and organize-imports.
-- Owns the <leader>co / <leader>cT / <leader>cR keymaps for TS/JS buffers.

local M = {}

local TEST_FILE_PATTERNS = {
  '%.test%.',
  '%.spec%.',
  '[/\\]__tests__[/\\]',
  '_test%.',
}

-- Command that runs a locally-installed binary, per package manager.
local EXEC = {
  npm = 'npx',
  yarn = 'yarn',
  pnpm = 'pnpm exec',
  bun = 'bunx',
}

local ROOT_MARKERS = { 'package.json', 'tsconfig.json', 'jsconfig.json', '.git' }

local function project_root(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr or 0)
  local start = name ~= '' and vim.fn.fnamemodify(name, ':p:h') or vim.fn.getcwd()
  return vim.fs.root(start, ROOT_MARKERS) or vim.fn.getcwd()
end

--- Resolve the package manager from lockfiles (bun > pnpm > yarn > npm).
--- @param bufnr integer
--- @return string
function M.package_manager(bufnr)
  local root = project_root(bufnr)
  local function has(file) return vim.fn.filereadable(vim.fs.joinpath(root, file)) == 1 end
  if has 'bun.lockb' or has 'bun.lock' then return 'bun' end
  if has 'pnpm-lock.yaml' then return 'pnpm' end
  if has 'yarn.lock' then return 'yarn' end
  return 'npm'
end

--- Decode package.json for the buffer's project (nil when absent/unreadable).
--- @param bufnr integer
--- @return table|nil
function M.package_json(bufnr)
  local path = vim.fs.joinpath(project_root(bufnr), 'package.json')
  if vim.fn.filereadable(path) ~= 1 then return nil end
  local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), '\n'))
  if not ok then return nil end
  return decoded
end

local function merge_deps(pkg)
  local deps = {}
  for _, field in ipairs { 'dependencies', 'devDependencies' } do
    for name in pairs((pkg or {})[field] or {}) do
      deps[name] = true
    end
  end
  return deps
end

--- Basename of the current buffer when it is itself a test/spec file.
local function current_test_file(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr or 0)
  if name == '' then return nil end
  for _, pat in ipairs(TEST_FILE_PATTERNS) do
    if name:match(pat) then return vim.fn.fnamemodify(name, ':t') end
  end
  return nil
end

local function run_in_terminal(cmd) vim.cmd('split | terminal ' .. cmd) end

--- Run the project's test runner (vitest/jest) or its `test` script.
--- @param bufnr integer
function M.run_tests(bufnr)
  local pm = M.package_manager(bufnr)
  local pkg = M.package_json(bufnr)
  local deps = merge_deps(pkg)
  local exec = EXEC[pm] or 'npx'

  local cmd, scoped
  if deps.vitest then
    cmd, scoped = exec .. ' vitest run', true
  elseif deps.jest then
    cmd, scoped = exec .. ' jest', true
  elseif pkg and (pkg.scripts or {}).test then
    cmd = pm .. ' test'
  else
    vim.notify('node: no test runner found (add vitest/jest or a "test" script)', vim.log.levels.WARN)
    return
  end

  -- Narrow to a single file when the open buffer is itself a test/spec file.
  local file = scoped and current_test_file(bufnr) or nil
  if file then cmd = cmd .. ' ' .. vim.fn.shellescape(file) end

  run_in_terminal(cmd)
end

--- Pick a package.json script and run it in a split terminal.
--- @param bufnr integer
function M.run_script(bufnr)
  local pkg = M.package_json(bufnr)
  local scripts = pkg and pkg.scripts
  if not scripts or vim.tbl_isempty(scripts) then
    vim.notify('node: no package.json scripts found', vim.log.levels.WARN)
    return
  end
  local names = vim.tbl_keys(scripts)
  table.sort(names)
  vim.ui.select(names, { prompt = 'Run script:' }, function(choice)
    if not choice then return end
    run_in_terminal(M.package_manager(bufnr) .. ' run ' .. choice)
  end)
end

local function organize_imports()
  -- ts_ls/effect_tsgo use `source.organizeImports`; biome uses its own kind.
  vim.lsp.buf.code_action {
    context = { only = { 'source.organizeImports', 'source.organizeImports.biome' } },
    apply = true,
  }
end

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('node-keymaps', { clear = true }),
  pattern = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
  callback = function(event)
    local buf = event.buf
    vim.keymap.set('n', '<leader>co', organize_imports, { buffer = buf, desc = '[C]ode [O]rganize imports' })
    vim.keymap.set('n', '<leader>cT', function() M.run_tests(buf) end, { buffer = buf, desc = '[C]ode [T]est' })
    vim.keymap.set('n', '<leader>cR', function() M.run_script(buf) end, { buffer = buf, desc = '[C]ode [R]un package script' })
  end,
})

return M
