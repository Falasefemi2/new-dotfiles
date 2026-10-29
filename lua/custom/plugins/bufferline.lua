-- lua/custom/plugins/bufferline.lua
-- VSCode-style buffer tabs. bufferline.nvim owns the tabline; lualine keeps the
-- statusline. Only listed real files are shown, and every close path goes
-- through config.buffers (mini.bufremove) so splits survive.
vim.pack.add { 'https://github.com/akinsho/bufferline.nvim' }

local api = vim.api

-- Single switch for the optional breadcrumb winbar.
local opts = {
  breadcrumbs = true,
}

local loaded = false
local ensure_setup

---A "real file" tab: listed, normal buffer with a name and no special scheme.
---@param buf integer
---@return boolean
local function is_real_file(buf)
  if not api.nvim_buf_is_valid(buf) then return false end
  if vim.bo[buf].buflisted ~= true then return false end
  if vim.bo[buf].buftype ~= '' then return false end
  local name = api.nvim_buf_get_name(buf)
  if name == '' then return false end
  return name:match '^%a[%w+.-]*://' == nil
end

local function real_file_count()
  local count = 0
  for _, buf in ipairs(api.nvim_list_bufs()) do
    if is_real_file(buf) then count = count + 1 end
  end
  return count
end

---@param name string
---@param attribute 'fg'|'bg'|'sp'
local function from(name, attribute) return { highlight = name, attribute = attribute } end

---Highlight values are resolved by bufferline from the live colorscheme, and
---re-resolved on ColorScheme, so switching themes never leaves stale colors.
local function highlights()
  local fill_bg = from('TabLineFill', 'bg')
  local normal_bg = from('Normal', 'bg')
  local normal_fg = from('Normal', 'fg')
  local comment_fg = from('Comment', 'fg')
  local accent = from('Function', 'fg')
  local sep_fg = from('WinSeparator', 'fg')
  local error_fg = from('DiagnosticError', 'fg')
  local warn_fg = from('DiagnosticWarn', 'fg')
  local directory_fg = from('Directory', 'fg')

  local function tab(fg, bg, selected)
    local value = { fg = fg, bg = bg }
    if selected then
      value.bold = true
      value.underline = true
      value.sp = accent
    end
    return value
  end

  return {
    fill = { fg = comment_fg, bg = fill_bg },
    background = { fg = comment_fg, bg = fill_bg },
    buffer = tab(comment_fg, fill_bg, false),
    buffer_visible = tab(normal_fg, fill_bg, false),
    buffer_selected = tab(normal_fg, normal_bg, true),
    close_button = { fg = comment_fg, bg = fill_bg },
    close_button_visible = { fg = normal_fg, bg = fill_bg },
    close_button_selected = tab(normal_fg, normal_bg, true),
    modified = { fg = normal_fg, bg = fill_bg },
    modified_visible = { fg = normal_fg, bg = fill_bg },
    modified_selected = tab(normal_fg, normal_bg, true),
    separator = { fg = sep_fg, bg = fill_bg },
    separator_visible = { fg = sep_fg, bg = fill_bg },
    separator_selected = tab(sep_fg, normal_bg, true),
    tab_separator = { fg = sep_fg, bg = fill_bg },
    tab_separator_selected = tab(sep_fg, normal_bg, true),
    indicator_selected = { fg = accent, bg = normal_bg },
    indicator_visible = { fg = normal_fg, bg = fill_bg },
    offset_separator = { fg = sep_fg, bg = fill_bg },
    trunc_marker = { fg = comment_fg, bg = fill_bg },
    diagnostic = { fg = comment_fg, bg = fill_bg },
    diagnostic_visible = { fg = comment_fg, bg = fill_bg },
    diagnostic_selected = { fg = normal_fg, bg = normal_bg },
    error = { fg = error_fg, bg = fill_bg },
    error_visible = { fg = error_fg, bg = fill_bg },
    error_selected = tab(error_fg, normal_bg, true),
    error_diagnostic = { fg = error_fg, bg = fill_bg },
    error_diagnostic_visible = { fg = error_fg, bg = fill_bg },
    error_diagnostic_selected = { fg = error_fg, bg = normal_bg },
    warning = { fg = warn_fg, bg = fill_bg },
    warning_visible = { fg = warn_fg, bg = fill_bg },
    warning_selected = tab(warn_fg, normal_bg, true),
    warning_diagnostic = { fg = warn_fg, bg = fill_bg },
    warning_diagnostic_visible = { fg = warn_fg, bg = fill_bg },
    warning_diagnostic_selected = { fg = warn_fg, bg = normal_bg },
    -- Hints and info are deliberately neutral: only errors/warnings get color.
    hint = { fg = comment_fg, bg = fill_bg },
    hint_visible = { fg = normal_fg, bg = fill_bg },
    hint_selected = tab(normal_fg, normal_bg, true),
    hint_diagnostic = { fg = comment_fg, bg = fill_bg },
    hint_diagnostic_visible = { fg = comment_fg, bg = fill_bg },
    hint_diagnostic_selected = { fg = normal_fg, bg = normal_bg },
    info = { fg = comment_fg, bg = fill_bg },
    info_visible = { fg = normal_fg, bg = fill_bg },
    info_selected = tab(normal_fg, normal_bg, true),
    info_diagnostic = { fg = comment_fg, bg = fill_bg },
    info_diagnostic_visible = { fg = comment_fg, bg = fill_bg },
    info_diagnostic_selected = { fg = normal_fg, bg = normal_bg },
    duplicate = { fg = directory_fg, bg = fill_bg, italic = true },
    duplicate_visible = { fg = directory_fg, bg = fill_bg, italic = true },
    duplicate_selected = { fg = directory_fg, bg = normal_bg, italic = true, underline = true, sp = accent },
  }
end

---Only errors/warnings produce a tab indicator; hints/info return an empty string.
local function diagnostics_indicator(_, _, diagnostics)
  local errors = diagnostics.error or 0
  local warnings = diagnostics.warning or 0
  if errors == 0 and warnings == 0 then return '' end
  local parts = {}
  if errors > 0 then parts[#parts + 1] = ' ✖' .. errors end
  if warnings > 0 then parts[#parts + 1] = ' ⚠' .. warnings end
  return table.concat(parts)
end

---Bufferline click handlers can run during redraw (fast event); defer the
---modal Save/Discard/Cancel prompt until it is safe.
local function close_buffer(buf)
  local function close() require('config.buffers').close(buf) end
  if vim.in_fast_event() then
    vim.schedule(close)
  else
    close()
  end
end

local function visible_elements()
  if ensure_setup then ensure_setup() end
  -- Populate bufferline's component order even when the tabline is not drawn.
  if _G.nvim_bufferline then pcall(_G.nvim_bufferline) end
  local ok, bufferline = pcall(require, 'bufferline')
  if not ok then return {} end
  local got, data = pcall(bufferline.get_elements)
  if not got or type(data) ~= 'table' then return {} end
  return data.elements or {}
end

local function close_others()
  local current = api.nvim_get_current_buf()
  for _, element in ipairs(visible_elements()) do
    if element.id ~= current and is_real_file(element.id) then
      if not require('config.buffers').close(element.id) then return end
    end
  end
end

local function close_right()
  local elements = visible_elements()
  local current = api.nvim_get_current_buf()
  local index
  for i, element in ipairs(elements) do
    if element.id == current then
      index = i
      break
    end
  end
  if not index then return end
  for i = index + 1, #elements do
    if not require('config.buffers').close(elements[i].id) then return end
  end
end

local function set_keymaps()
  local function map(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { desc = 'Bufferline: ' .. desc, silent = true }) end
  local function run(cmd)
    return function()
      ensure_setup()
      vim.cmd(cmd)
    end
  end

  map('<S-h>', run 'BufferLineCyclePrev', 'previous tab')
  map('<S-l>', run 'BufferLineCycleNext', 'next tab')
  for i = 1, 9 do
    map('<leader>' .. i, run(('BufferLineGoToBuffer %d'):format(i)), ('go to tab %d'):format(i))
  end
  map('<leader>bp', run 'BufferLineTogglePin', 'toggle pin')
  map('<leader>bo', close_others, 'close other tabs')
  map('<leader>bc', close_right, 'close tabs to the right')
end

local function refresh_visibility()
  -- Count real files, not every listed buffer: help/quickfix/terminals must
  -- not make the bar appear.
  vim.o.showtabline = real_file_count() > 1 and 2 or 0
end

---Load bufferline on the first real file instead of at startup. vim.pack has no
---lazy-loading API, so the plugin is on the runtimepath but setup is deferred.
ensure_setup = function()
  if loaded then return end
  loaded = true

  require('bufferline').setup {
    options = {
      mode = 'buffers',
      -- Visibility is controlled below so the count is "real files", not all
      -- listed buffers. auto_toggle stays off to keep bufferline from fighting it.
      always_show_bufferline = false,
      auto_toggle_bufferline = false,
      custom_filter = is_real_file,
      separator_style = 'thin',
      indicator = { style = 'underline' },
      show_buffer_icons = true,
      show_buffer_close_icons = true,
      show_close_icon = false,
      show_tab_indicators = true,
      color_icons = true,
      buffer_close_icon = '✕',
      modified_icon = '●',
      close_icon = '✕',
      left_trunc_marker = '<',
      right_trunc_marker = '>',
      max_name_length = 28,
      show_duplicate_prefix = true,
      duplicates_across_groups = true,
      close_command = close_buffer,
      middle_mouse_command = close_buffer,
      right_mouse_command = false,
      left_mouse_command = 'buffer %d',
      diagnostics = 'nvim_lsp',
      diagnostics_indicator = diagnostics_indicator,
      offsets = {
        { filetype = 'neo-tree', text = 'Explorer', highlight = 'Directory', separator = true },
      },
    },
    highlights = highlights,
  }

  refresh_visibility()
  if opts.breadcrumbs then require('config.breadcrumbs').enable() end
end

local lazy_group = api.nvim_create_augroup('BufferlineLazy', { clear = true })
api.nvim_create_autocmd({ 'BufAdd', 'BufReadPre' }, {
  group = lazy_group,
  callback = function(args)
    if is_real_file(args.buf) then ensure_setup() end
  end,
})
api.nvim_create_autocmd('VimEnter', {
  group = lazy_group,
  callback = function()
    if is_real_file(api.nvim_get_current_buf()) then ensure_setup() end
  end,
})

local visibility_group = api.nvim_create_augroup('BufferlineVisibility', { clear = true })
api.nvim_create_autocmd({ 'BufAdd', 'BufDelete', 'BufWipeout', 'BufFilePost', 'BufEnter', 'TabEnter', 'VimEnter' }, {
  group = visibility_group,
  callback = refresh_visibility,
})
refresh_visibility()

set_keymaps()

return { opts = opts, is_real_file = is_real_file }
