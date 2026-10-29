-- lua/config/breadcrumbs.lua
-- Optional VSCode-style path breadcrumb in the winbar: src > Pages > File.jsx
--
-- Enabled from custom.plugins.bufferline behind a single flag. Colors are
-- derived from the active colorscheme on every ColorScheme event, and floats
-- (including the floating terminals) always get an empty winbar.

local M = { enabled = false }

local api = vim.api

local EXPR = "%{%v:lua.require'config.breadcrumbs'.render()%}"
local GROUP = 'config-breadcrumbs'

local function is_float(win)
  local ok, cfg = pcall(api.nvim_win_get_config, win)
  return ok and cfg.relative ~= ''
end

---@param buf integer
---@return boolean
local function is_eligible(buf)
  if not api.nvim_buf_is_valid(buf) then return false end
  if vim.bo[buf].buftype ~= '' then return false end
  local name = api.nvim_buf_get_name(buf)
  if name == '' then return false end
  -- oil://, fugitive://, and friends are views, not files.
  if name:match '^%a[%w+.-]*://' then return false end
  return true
end

local function define_highlights()
  local normal = api.nvim_get_hl(0, { name = 'Normal', link = false })
  local comment = api.nvim_get_hl(0, { name = 'Comment', link = false })
  local winbar = api.nvim_get_hl(0, { name = 'WinBar', link = false })
  local bg = winbar.bg or normal.bg
  api.nvim_set_hl(0, 'BreadcrumbDir', { fg = comment.fg or normal.fg, bg = bg })
  api.nvim_set_hl(0, 'BreadcrumbSep', { fg = comment.fg or normal.fg, bg = bg })
  api.nvim_set_hl(0, 'BreadcrumbFile', { fg = normal.fg, bg = bg, bold = true })
end

local function escape(text) return (text:gsub('%%', '%%%%')) end

---Render the breadcrumb for the window currently being drawn.
---@return string
function M.render()
  local win = tonumber(vim.g.statusline_winid) or api.nvim_get_current_win()
  if not api.nvim_win_is_valid(win) or is_float(win) then return '' end

  local buf = api.nvim_win_get_buf(win)
  if not is_eligible(buf) then return '' end

  local name = api.nvim_buf_get_name(buf)
  local relative = vim.fn.fnamemodify(name, ':~:.')
  local parts = vim.split(relative, '[/\\]', { trimempty = true })
  if #parts == 0 then return '' end

  local out = {}
  for i, part in ipairs(parts) do
    if i == #parts then
      out[#out + 1] = '%#BreadcrumbFile#' .. escape(part)
    else
      out[#out + 1] = '%#BreadcrumbDir#' .. escape(part)
      out[#out + 1] = '%#BreadcrumbSep# > '
    end
  end
  return table.concat(out)
end

---Apply the current winbar state to every window.
function M.apply()
  if not M.enabled then return end
  for _, win in ipairs(api.nvim_list_wins()) do
    local buf = api.nvim_win_get_buf(win)
    local wanted = (not is_float(win) and is_eligible(buf)) and EXPR or ''
    if vim.wo[win].winbar ~= wanted then vim.wo[win].winbar = wanted end
  end
end

function M.enable()
  if M.enabled then return M end
  M.enabled = true
  define_highlights()

  local group = api.nvim_create_augroup(GROUP, { clear = true })
  local events = { 'BufEnter', 'BufFilePost', 'FileType', 'WinEnter', 'WinNew', 'DirChanged', 'VimEnter' }
  api.nvim_create_autocmd(events, { group = group, callback = M.apply })
  api.nvim_create_autocmd('ColorScheme', {
    group = group,
    callback = function()
      define_highlights()
      M.apply()
    end,
  })

  M.apply()
  return M
end

function M.disable()
  if not M.enabled then return M end
  M.enabled = false
  pcall(api.nvim_del_augroup_by_name, GROUP)
  for _, win in ipairs(api.nvim_list_wins()) do
    if vim.wo[win].winbar == EXPR then vim.wo[win].winbar = '' end
  end
  return M
end

return M
