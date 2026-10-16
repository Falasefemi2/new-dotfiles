-- grapple.lua
-- Persistent, per-project file marks: tag the files you keep returning to and
-- jump straight back (cursor position included). Harpoon-like, but zero setup
-- and scoped to the git repo. https://github.com/cbochs/grapple.nvim
vim.pack.add { 'https://github.com/cbochs/grapple.nvim' }

require('grapple').setup {
  -- Tags are stored per git repository (falls back to cwd outside a repo).
  scope = 'git',
}

-- <leader>m = [M]arks
vim.keymap.set('n', '<leader>mt', '<cmd>Grapple toggle<cr>', { desc = '[M]ark: [T]oggle tag on current file' })
vim.keymap.set('n', '<leader>mT', '<cmd>Grapple toggle_tags<cr>', { desc = '[M]ark: open [T]ags window' })
vim.keymap.set('n', '<leader>m]', '<cmd>Grapple cycle_tags next<cr>', { desc = '[M]ark: cycle to next tag' })
vim.keymap.set('n', '<leader>m[', '<cmd>Grapple cycle_tags prev<cr>', { desc = '[M]ark: cycle to previous tag' })
