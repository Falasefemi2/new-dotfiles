vim.pack.add { 'https://github.com/nvim-lualine/lualine.nvim' }

-- A colored devicon resolved per file by mini.icons (mocked as
-- nvim-web-devicons). The filetype component resolves the icon from the
-- filename first, so package.json / .tsx / Makefile each get their own.
-- `separator = ''` keeps the icon glued to the filename instead of putting a
-- `│` between them; `padding` is 0 because the icon already ends in a space.
local file_icon = {
  'filetype',
  icon_only = true,
  colored = true,
  separator = '',
  padding = { left = 0, right = 0 },
}

-- Match the sign-column glyphs in config/options.lua so the statusline and
-- the gutter never disagree about what an error looks like.
local diagnostic_symbols = {
  error = '󰅚 ',
  warn = '󰀦 ',
  info = '󰋽 ',
  hint = '󰌶 ',
}

-- Defer lualine past first render (statusline appears <50ms after UIEnter).
-- Icons resolve through mini.icons (mocked as nvim-web-devicons).
vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('lazy-lualine', { clear = true }),
  callback = function()
    vim.schedule(function()
      require('lualine').setup {
        options = {
          icons_enabled = true,
          -- `auto` follows the active colorscheme; config.colors refreshes
          -- lualine on every ColorScheme event so nothing renders stale.
          theme = 'auto',
          component_separators = { left = '│', right = '│' },
          section_separators = { left = '', right = '' },
          disabled_filetypes = {
            statusline = { 'neo-tree' },
            winbar = {},
          },
          globalstatus = true,
          refresh = {
            statusline = 1000,
            tabline = 1000,
            winbar = 1000,
          },
        },
        sections = {
          lualine_a = { { 'mode', fmt = function(str) return str:sub(1, 1) end } },
          lualine_b = { 'branch' },
          lualine_c = {
            file_icon,
            { 'filename', file_status = true, path = 1, padding = { left = 0, right = 1 } },
            { 'diff', symbols = { added = '+', modified = '~', removed = '-' } },
            -- Colors come from the active theme's Diagnostic* groups, so this
            -- stays correct across the whole theme switcher instead of being
            -- pinned to Catppuccin.
            { 'diagnostics', symbols = diagnostic_symbols },
          },
          lualine_x = {
            { 'lsp_status', icon = '󰒋', ignore_lsp = { 'null-ls', 'copilot' } },
            'encoding',
            -- The devicon already sits next to the filename; keep this as text.
            { 'filetype', icons_enabled = false },
          },
          lualine_y = { 'progress' },
          lualine_z = { 'location' },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { 'filename' },
          lualine_x = { 'location' },
          lualine_y = {},
          lualine_z = {},
        },
        extensions = { 'neo-tree' },
      }
    end)
  end,
})
