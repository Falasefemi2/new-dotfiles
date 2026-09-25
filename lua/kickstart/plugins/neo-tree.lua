-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

-- plenary comes from SECTION 4 (telescope), nui from noice.lua; not duplicated here.
local plugins = {
  { src = 'https://github.com/nvim-neo-tree/neo-tree.nvim', version = vim.version.range '*' },
}

if vim.g.have_nerd_font then
  table.insert(plugins, 'https://github.com/nvim-tree/nvim-web-devicons') -- not strictly required, but recommended
end

vim.pack.add(plugins)

-- Lazy 10ms setup until first \ (saves on startup, vim.pack still ensures plugin installed)
local _neotree_setup = false
local function ensure_neotree()
  if _neotree_setup then return end
  _neotree_setup = true
  require('neo-tree').setup {
    filesystem = {
      filtered_items = { visible = true, hide_dotfiles = false, hide_gitignored = false, hide_by_name = { 'node_modules', '.git', '__pycache__' } },
      follow_current_file = { enabled = true },
      use_libuv_file_watcher = true,
      window = { position = 'right', mappings = { ['\\'] = 'close_window' } },
    },
  }
end

vim.keymap.set('n', '\\', function()
  ensure_neotree()
  vim.cmd 'Neotree reveal'
end, { desc = 'NeoTree reveal', silent = true })
