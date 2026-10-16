-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

-- plenary comes from SECTION 4 (telescope), nui from noice.lua; not duplicated here.
-- Icons are provided by `mini.icons` (see init.lua SECTION 3), which mocks the
-- nvim-web-devicons API neo-tree expects - so no separate devicons plugin here.
vim.pack.add {
  { src = 'https://github.com/nvim-neo-tree/neo-tree.nvim', version = vim.version.range '*' },
}

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
