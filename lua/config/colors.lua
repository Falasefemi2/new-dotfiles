-- lua/config/colors.lua
-- Self-contained theme manager for a vim.pack-based config.
--
-- - Curated set of 12 vivid themes. All are *registered* with `vim.pack.add`
--   at startup (cheap: no setup runs), but only the active theme is
--   configured + applied, so startup stays fast. Switching to a theme whose
--   plugin is present but not yet sourced first runs `:packadd`.
-- - `<leader>uc` picker (Telescope when available, `vim.ui.select`
--   fallback) with live preview; `<Esc>` reverts to the previous theme.
-- - `<leader>un` / `<leader>up` cycle, `<leader>ur` random,
--   `<leader>ut` transparency toggle, `<leader>uC` custom hex accent.
-- - Choice (theme, transparency, accent) persists to
--   `stdpath('data')/colorscheme.json` and is restored synchronously when
--   this module is required from init.lua, before the UI draws.
-- - A dedicated `config-colors` augroup (clear = true) re-applies the
--   transparency + accent overrides and refreshes lualine on ColorScheme.

local M = {}

---@class ConfigColorsTheme
---@field pack string Directory/name passed to `:packadd` (matches `vim.pack.add` spec `name`)
---@field colorscheme string Name passed to `:colorscheme`
---@field setup? fun(transparent: boolean) Theme setup with transparency support

---Ordered theme list. `tokyonight-night` is the default (most vivid,
---first-class treesitter/LSP/telescope/neo-tree/gitsigns/cmp support).
---@type (ConfigColorsTheme & { label: string })[]
local THEMES = {
  {
    label = 'tokyonight-night',
    pack = 'tokyonight',
    colorscheme = 'tokyonight-night',
    setup = function(transparent)
      require('tokyonight').setup { style = 'night', transparent = transparent, terminal_colors = true }
    end,
  },
  {
    label = 'catppuccin-mocha',
    pack = 'catppuccin',
    colorscheme = 'catppuccin-mocha',
    setup = function(transparent)
      require('catppuccin').setup {
        flavour = 'mocha',
        background = { light = 'latte', dark = 'mocha' },
        transparent_background = transparent,
        term_colors = true,
        integrations = {
          cmp = true,
          gitsigns = true,
          mason = true,
          mini = { enabled = true },
          native_lsp = { enabled = true },
          neotree = true,
          noice = true,
          notify = true,
          telescope = { enabled = true },
          treesitter = true,
          which_key = true,
          dap = true,
          dap_ui = true,
          indent_blankline = { enabled = true },
        },
      }
    end,
  },
  {
    label = 'kanagawa-dragon',
    pack = 'kanagawa',
    colorscheme = 'kanagawa-dragon',
    setup = function(transparent) require('kanagawa').setup { theme = 'dragon', transparent = transparent } end,
  },
  {
    label = 'rose-pine',
    pack = 'rose-pine',
    colorscheme = 'rose-pine',
    setup = function(transparent)
      require('rose-pine').setup { variant = 'main', dark_variant = 'main', styles = { transparency = transparent } }
    end,
  },
  {
    label = 'cyberdream',
    pack = 'cyberdream',
    colorscheme = 'cyberdream',
    setup = function(transparent) require('cyberdream').setup { transparent = transparent, terminal_colors = true } end,
  },
  { label = 'oxocarbon', pack = 'oxocarbon', colorscheme = 'oxocarbon' },
  {
    label = 'nightfox',
    pack = 'nightfox',
    colorscheme = 'nightfox',
    setup = function(transparent) require('nightfox').setup { options = { transparent = transparent } } end,
  },
  {
    label = 'onedark-dark',
    pack = 'onedarkpro',
    colorscheme = 'onedark_dark',
    setup = function(transparent) require('onedarkpro').setup { options = { transparency = transparent } } end,
  },
  {
    label = 'github-dark-high-contrast',
    pack = 'github-nvim-theme',
    colorscheme = 'github_dark_high_contrast',
    setup = function(transparent) require('github-theme').setup { options = { transparent = transparent } } end,
  },
  {
    label = 'vscode',
    pack = 'vscode-nvim',
    colorscheme = 'vscode',
    setup = function(transparent) require('vscode').setup { transparent = transparent } end,
  },
  {
    label = 'everforest-hard',
    pack = 'everforest',
    colorscheme = 'everforest',
    setup = function(transparent)
      require('everforest').setup { background = 'hard', transparent_background_level = transparent and 2 or 0 }
    end,
  },
  { label = 'gruvbox-material', pack = 'gruvbox-material', colorscheme = 'gruvbox-material' },
}

---@param repo string
---@return string
local function gh(repo) return 'https://github.com/' .. repo end

-- Register every theme plugin (no setup runs here: only the active theme
-- is loaded at startup, the rest on first switch).
pcall(vim.pack.add, {
  { src = gh 'folke/tokyonight.nvim', name = 'tokyonight' },
  { src = gh 'catppuccin/nvim', name = 'catppuccin' },
  { src = gh 'rebelot/kanagawa.nvim', name = 'kanagawa' },
  { src = gh 'rose-pine/neovim', name = 'rose-pine' },
  { src = gh 'scottmckendry/cyberdream.nvim', name = 'cyberdream' },
  { src = gh 'nyoom-engineering/oxocarbon.nvim', name = 'oxocarbon' },
  { src = gh 'EdenEast/nightfox.nvim', name = 'nightfox' },
  { src = gh 'olimorris/onedarkpro.nvim', name = 'onedarkpro' },
  { src = gh 'projekt0n/github-nvim-theme', name = 'github-nvim-theme' },
  { src = gh 'Mofiqul/vscode.nvim', name = 'vscode-nvim' },
  { src = gh 'neanias/everforest-nvim', name = 'everforest' },
  { src = gh 'sainnhe/gruvbox-material', name = 'gruvbox-material' },
})

local STATE_FILE = vim.fn.stdpath 'data' .. '/colorscheme.json'
local DEFAULT_THEME = 'tokyonight-night'

local state = { theme = DEFAULT_THEME, transparent = false, accent = nil }

---@param label string
---@return ConfigColorsTheme?
local function find_theme(label)
  for _, t in ipairs(THEMES) do
    if t.label == label then return t end
  end
  return nil
end

---@return string[]
local function theme_names()
  local names = {}
  for _, t in ipairs(THEMES) do
    table.insert(names, t.label)
  end
  return names
end

local function persist()
  local ok, encoded = pcall(vim.json.encode, state)
  if not ok then return end
  pcall(vim.fn.writefile, { encoded }, STATE_FILE)
end

local function restore()
  if vim.fn.filereadable(STATE_FILE) ~= 1 then return end
  local ok, lines = pcall(vim.fn.readfile, STATE_FILE)
  if not ok or not lines then return end
  local ok2, decoded = pcall(vim.json.decode, table.concat(lines, '\n'))
  if not ok2 or type(decoded) ~= 'table' then return end -- corrupt file: keep defaults
  if type(decoded.theme) == 'string' and find_theme(decoded.theme) then state.theme = decoded.theme end
  if type(decoded.transparent) == 'boolean' then state.transparent = decoded.transparent end
  if type(decoded.accent) == 'string' and decoded.accent:match '^#%x%x%x%x%x%x$' then
    state.accent = decoded.accent
  end
end

-- Groups cleared to plain (no bg) when transparency is on. Only groups
-- without a `link` are touched so theme links never break. Runs on every
-- ColorScheme so it survives theme switches.
local TRANSPARENT_GROUPS = {
  'Normal',
  'NormalNC',
  'NormalFloat',
  'SignColumn',
  'MsgArea',
  'TelescopeNormal',
  'TelescopeBorder',
  'NeoTreeNormal',
  'NeoTreeNormalNC',
  'NeoTreeEndOfBuffer',
}

local function apply_transparency()
  if not state.transparent then return end
  for _, group in ipairs(TRANSPARENT_GROUPS) do
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group })
    if ok and hl and hl.link == nil then
      hl.bg = 'NONE'
      if hl.ctermbg ~= nil then hl.ctermbg = 'NONE' end
      pcall(vim.api.nvim_set_hl, 0, group, hl)
    end
  end
end

-- Accent override: cursor line, selection(s), cursor-line number and border
-- highlights. Re-applied on every ColorScheme until cleared.
local function apply_accent()
  local accent = state.accent
  if not accent then return end
  pcall(vim.api.nvim_set_hl, 0, 'CursorLine', { bg = accent })
  pcall(vim.api.nvim_set_hl, 0, 'Visual', { bg = accent })
  pcall(vim.api.nvim_set_hl, 0, 'PmenuSel', { bg = accent })
  pcall(vim.api.nvim_set_hl, 0, 'CursorLineNr', { fg = accent })
  for _, group in ipairs { 'FloatBorder', 'WinSeparator', 'TelescopeBorder', 'TelescopePromptPrefix' } do
    pcall(vim.api.nvim_set_hl, 0, group, { fg = accent })
  end
end

local function refresh_statusline()
  -- lualine uses `auto` theme (see custom.plugins.lualine) and follows the
  -- active colorscheme; force a redraw so nothing renders stale.
  pcall(function() require('lualine').refresh() end)
end

vim.api.nvim_create_augroup('config-colors', { clear = true })
vim.api.nvim_create_autocmd('ColorScheme', {
  group = 'config-colors',
  desc = 'Re-apply transparency/accent overrides and refresh statusline',
  callback = function()
    apply_transparency()
    apply_accent()
    refresh_statusline()
  end,
})

---@param label string
---@param opts? { persist?: boolean }
---@return boolean ok
function M.apply(label, opts)
  opts = opts or {}
  local theme = find_theme(label)
  if not theme then
    vim.notify(('colors: unknown theme %q'):format(label), vim.log.levels.ERROR)
    return false
  end
  -- Load the theme plugin on demand when switching to one that has not
  -- been sourced yet (only the active theme loads at startup).
  pcall(vim.cmd.packadd, theme.pack)
  if theme.pack == 'gruvbox-material' then
    vim.g.gruvbox_material_background = 'hard'
    vim.g.gruvbox_material_transparent_background = state.transparent and 1 or 0
  end
  if theme.setup then
    local ok, err = pcall(theme.setup, state.transparent)
    if not ok then
      vim.notify(('colors: setup failed for %s: %s'):format(label, err), vim.log.levels.ERROR)
      return false
    end
  end
  local ok = pcall(vim.cmd.colorscheme, theme.colorscheme)
  if not ok then
    vim.notify(('colors: colorscheme %q not available (plugin not installed?)'):format(theme.colorscheme), vim.log.levels.WARN)
    return false
  end
  state.theme = label
  if opts.persist ~= false then persist() end
  return true
end

---@return string current theme label
function M.current() return state.theme end

---@return string[] all theme labels
function M.list() return theme_names() end

---@param step integer +1 next, -1 previous
function M.cycle(step)
  local names = theme_names()
  local idx = 1
  for i, name in ipairs(names) do
    if name == state.theme then
      idx = i
      break
    end
  end
  local next_idx = ((idx - 1 + step) % #names) + 1
  M.apply(names[next_idx])
end

function M.random()
  local names = {}
  for _, name in ipairs(theme_names()) do
    if name ~= state.theme then table.insert(names, name) end
  end
  if #names == 0 then return end
  math.randomseed(os.time() + vim.uv.hrtime() % 100000)
  M.apply(names[math.random(#names)])
end

function M.toggle_transparent()
  state.transparent = not state.transparent
  M.apply(state.theme)
  vim.notify('Transparency ' .. (state.transparent and 'on' or 'off'), vim.log.levels.INFO)
end

function M.custom_accent()
  vim.ui.input({ prompt = 'Accent hex color (e.g. #ff007c, empty clears): ' }, function(input)
    if input == nil then return end -- <Esc>: keep current accent
    if input == '' then
      state.accent = nil
      persist()
      M.apply(state.theme) -- re-apply without accent
      vim.notify('Accent cleared', vim.log.levels.INFO)
      return
    end
    local hex = input:match '^%s*(#?%x%x%x%x%x%x)%s*$'
    if not hex then
      vim.notify(('colors: %q is not a hex color'):format(input), vim.log.levels.ERROR)
      return
    end
    if hex:sub(1, 1) ~= '#' then hex = '#' .. hex end
    state.accent = hex
    persist()
    apply_accent()
    refresh_statusline()
    vim.notify('Accent set to ' .. hex, vim.log.levels.INFO)
  end)
end

-- Picker with live preview: moving through the list applies each theme,
-- `<CR>` confirms + persists, `<Esc>`/close reverts to the previous theme.
function M.pick()
  local has_telescope, pickers, finders, conf, actions, action_state
  has_telescope = pcall(function()
    pickers = require 'telescope.pickers'
    finders = require 'telescope.finders'
    conf = require 'telescope.config'
    actions = require 'telescope.actions'
    action_state = require 'telescope.actions.state'
  end)
  if not has_telescope then
    vim.ui.select(theme_names(), { prompt = 'Colorscheme:' }, function(choice)
      if choice then M.apply(choice) end
    end)
    return
  end

  local original = state.theme
  local confirmed = false
  local picker = pickers.new({}, {
    prompt_title = 'Colorscheme (live preview, <CR> saves, <Esc> reverts)',
    finder = finders.new_table { results = theme_names() },
    sorter = conf.values.generic_sorter {},
    previewer = false,
    attach_mappings = function(prompt_bufnr, map)
      local function preview_selected()
        local entry = action_state.get_selected_entry()
        if entry then M.apply(entry.value or entry[1], { persist = false }) end
      end
      local function move_and_preview(next)
        return function(pbuf)
          if next then
            actions.move_selection_next(pbuf)
          else
            actions.move_selection_previous(pbuf)
          end
          preview_selected()
        end
      end
      map('i', '<Down>', move_and_preview(true))
      map('i', '<Up>', move_and_preview(false))
      map('i', '<C-n>', move_and_preview(true))
      map('i', '<C-p>', move_and_preview(false))
      map('n', '<Down>', move_and_preview(true))
      map('n', '<Up>', move_and_preview(false))
      map('n', 'j', move_and_preview(true))
      map('n', 'k', move_and_preview(false))
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        confirmed = true
        if entry then M.apply(entry.value or entry[1]) end
      end)
      return true
    end,
  })
  picker:find()
  -- Revert when the picker closes without confirmation (e.g. <Esc>).
  local prompt_buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_create_autocmd('BufWipeout', {
    group = 'config-colors',
    buffer = prompt_buf,
    once = true,
    desc = 'Revert colorscheme preview on picker cancel',
    callback = function()
      if not confirmed then M.apply(original, { persist = false }) end
    end,
  })
  -- Preview the first entry right away so the list matches the screen.
  vim.schedule(function()
    if not confirmed then
      local entry = action_state.get_selected_entry()
      if entry then M.apply(entry.value or entry[1], { persist = false }) end
    end
  end)
end

-- Restore persisted choice, then apply before the UI draws. Missing/corrupt
-- file falls back to the default; a theme whose plugin is missing falls
-- back to the already-installed catppuccin, then to no explicit scheme.
restore()
if not M.apply(state.theme, { persist = false }) then
  if state.theme ~= 'catppuccin-mocha' then M.apply('catppuccin-mocha', { persist = false }) end
end

-- stylua: ignore
vim.keymap.set('n', '<leader>uc', function() M.pick() end, { desc = '[U]I [C]olorscheme picker (live preview)' })
vim.keymap.set('n', '<leader>un', function() M.cycle(1) end, { desc = '[U]I [N]ext colorscheme' })
vim.keymap.set('n', '<leader>up', function() M.cycle(-1) end, { desc = '[U]I [P]revious colorscheme' })
vim.keymap.set('n', '<leader>ur', function() M.random() end, { desc = '[U]I [R]andom colorscheme' })
vim.keymap.set('n', '<leader>ut', function() M.toggle_transparent() end, { desc = '[U]I [T]oggle transparent background' })
vim.keymap.set('n', '<leader>uC', function() M.custom_accent() end, { desc = '[U]I [C]ustom accent hex color' })

return M
