vim.pack.add { 'https://github.com/nvim-lualine/lualine.nvim' }

local function lsp_status()
  local buf_clients = vim.lsp.get_clients { bufnr = 0 }
  if #buf_clients == 0 then return 'No LSP' end
  local client_names = {}
  for _, client in ipairs(buf_clients) do
    if client.name ~= 'null-ls' and client.name ~= 'copilot' then table.insert(client_names, client.name) end
  end
  if #client_names == 0 then return 'LSP' end
  return '󰒋 ' .. table.concat(client_names, ', ')
end

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
            { 'filename', file_status = true, path = 1 },
            { 'diff', symbols = { added = '+', modified = '~', removed = '-' } },
            {
              'diagnostics',
              symbols = { error = 'E:', warn = 'W:', info = 'I:', hint = 'H:' },
              diagnostics_color = {
                error = { fg = '#f38ba8' },
                warn = { fg = '#f9e2af' },
                info = { fg = '#89dceb' },
                hint = { fg = '#a6e3a1' },
              },
            },
          },
          lualine_x = { lsp_status, 'encoding', 'filetype' },
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
