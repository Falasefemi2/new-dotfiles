-- lua/custom/plugins/bufferline.lua
-- NvChad "tabufline"-style buffer tabs. bufferline.nvim owns the tabline;
-- lualine keeps the statusline. Every buffer is one padded cell of the same
-- width with a devicon, its filename and a close/modified glyph.
--
-- Colours are never hardcoded: `highlights()` reads the active colorscheme
-- through nvim_get_hl and bufferline's own ColorScheme autocommand calls that
-- function again, so switching themes with the <leader>uc picker recolours
-- the bar without a restart.
vim.pack.add { 'https://github.com/akinsho/bufferline.nvim' }

local api = vim.api

-- Width of one cell in columns (icon + filename + modified/close glyph).
local TAB_SIZE = 24
-- Filename column: keeps names left-aligned and pushes the close/modified glyph
-- to the right edge of the cell. Bufferline truncates to ~20 at TAB_SIZE 24, so
-- 18 always fits.
local NAME_WIDTH = TAB_SIZE - 6
-- Fill: Normal bg scaled this far towards black. Multiplying RGB by a factor
-- below 1 always lowers luminance, which is what "one shade darker" means for
-- both dark and light themes.
local FILL_SHADE = 0.9

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

---Pad the filename to a fixed column so every cell is the same width and the
---close/modified glyph lines up at its right edge (bufferline itself centres
---whatever space is left over).
---@param buf { name: string }
---@return string
local function name_formatter(buf)
  local width = vim.fn.strwidth(buf.name)
  if width >= NAME_WIDTH then return buf.name end
  return buf.name .. string.rep(' ', NAME_WIDTH - width)
end

-- ============================================================
-- Colours
-- ============================================================

---Read one attribute from a live highlight group.
---@param name string
---@param attribute 'fg'|'bg'
---@return integer|nil
local function attr(name, attribute)
  local ok, value = pcall(api.nvim_get_hl, 0, { name = name, link = false })
  if not ok then return nil end
  return value[attribute]
end

---Scale an RGB colour towards black. nvim_get_hl yields 0xRRGGBB integers, so
---no hex strings are involved anywhere.
---@param color integer|nil
---@return integer|nil
local function darken(color)
  if type(color) ~= 'number' then return nil end
  local function channel(shift)
    local value = math.floor(bit.band(bit.rshift(color, shift), 0xff) * FILL_SHADE + 0.5)
    return math.min(255, math.max(0, value))
  end
  return bit.bor(bit.lshift(channel(16), 16), bit.lshift(channel(8), 8), channel(0))
end

---Derived from the colorscheme each time bufferline (re)applies highlights.
local function highlights()
  local normal_bg = attr('Normal', 'bg')
  local normal_fg = attr('Normal', 'fg') or attr('NormalFloat', 'fg')
  local dim_fg = attr('Comment', 'fg') or attr('NonText', 'fg') or normal_fg
  -- Transparency (<leader>ut) clears Normal's bg; there is nothing to darken
  -- then, so the bar and the active tab stay transparent with the editor.
  local fill_bg = darken(normal_bg)
  -- A nil value means "leave the group alone", so under transparency (no bg)
  -- these background-only groups are explicitly cleared with 'NONE' instead of
  -- keeping a stale colour from a previous theme.
  local cell_bg = normal_bg or 'NONE'
  local bar_bg = fill_bg or 'NONE'

  return {
    fill = { fg = dim_fg, bg = fill_bg },
    background = { fg = dim_fg, bg = fill_bg },
    buffer = { fg = dim_fg, bg = fill_bg },
    buffer_visible = { fg = dim_fg, bg = fill_bg },
    buffer_selected = { fg = normal_fg, bg = normal_bg, bold = true, italic = false },
    close_button = { fg = dim_fg, bg = fill_bg },
    close_button_visible = { fg = dim_fg, bg = fill_bg },
    close_button_selected = { fg = normal_fg, bg = normal_bg, italic = false },
    modified = { fg = dim_fg, bg = fill_bg },
    modified_visible = { fg = dim_fg, bg = fill_bg },
    modified_selected = { fg = normal_fg, bg = normal_bg, bold = true, italic = false },
    -- `indicator.style = 'none'` still emits one padding cell; colour it like
    -- the cell behind it so no stray block shows up.
    indicator_selected = { fg = cell_bg, bg = cell_bg },
    indicator_visible = { fg = bar_bg, bg = bar_bg },
    -- No separators are drawn (separator_style = { '', '' }); these groups
    -- exist anyway, so blend them into the tab they belong to.
    separator = { fg = bar_bg, bg = bar_bg },
    separator_visible = { fg = bar_bg, bg = bar_bg },
    separator_selected = { fg = cell_bg, bg = cell_bg },
    tab_separator = { fg = bar_bg, bg = bar_bg },
    tab_separator_selected = { fg = cell_bg, bg = cell_bg },
    offset_separator = { fg = bar_bg, bg = bar_bg },
    trunc_marker = { fg = dim_fg, bg = fill_bg },
    duplicate = { fg = dim_fg, bg = fill_bg },
    duplicate_visible = { fg = dim_fg, bg = fill_bg },
    duplicate_selected = { fg = normal_fg, bg = normal_bg, bold = true, italic = false },
  }
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
      numbers = 'none',
      -- Visibility is controlled below so the count is "real files", not all
      -- listed buffers. auto_toggle stays off to keep bufferline from fighting it.
      always_show_bufferline = false,
      auto_toggle_bufferline = false,
      custom_filter = is_real_file,

      -- Tabufline look: equal-width padded cells, no separators, no
      -- underline/indicator, no diagnostics, no duplicate paths.
      themable = false, -- derived colours always win over a theme's defaults
      separator_style = { '', '' },
      indicator = { style = 'none' },
      enforce_regular_tabs = true,
      tab_size = TAB_SIZE,
      name_formatter = name_formatter,

      show_buffer_icons = true,
      color_icons = true,
      show_buffer_close_icons = true,
      buffer_close_icon = '×',
      close_icon = '×', -- only used by the tab-page button, which is off
      modified_icon = '●',
      show_close_icon = false,
      show_tab_indicators = true,
      show_duplicate_prefix = false,
      duplicates_across_groups = false,
      truncate_names = true,
      left_trunc_marker = '<',
      right_trunc_marker = '>',

      close_command = close_buffer,
      middle_mouse_command = close_buffer,
      right_mouse_command = false,
      left_mouse_command = 'buffer %d',

      diagnostics = false,

      offsets = {
        -- neo-tree is a right sidebar (see kickstart.plugins.neo-tree). An
        -- empty text keeps the offset blank while reserving its full width.
        { filetype = 'neo-tree', text = '', highlight = 'BufferLineFill' },
      },
    },
    highlights = highlights,
  }

  refresh_visibility()
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

return { is_real_file = is_real_file }
