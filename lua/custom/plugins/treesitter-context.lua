-- treesitter-context.lua
-- Sticky header showing the enclosing function/class/block, so you never lose
-- your place in a long file. https://github.com/nvim-treesitter/nvim-treesitter-context
vim.pack.add { 'https://github.com/nvim-treesitter/nvim-treesitter-context' }

require('treesitter-context').setup {
  max_lines = 4, -- clamp how many context lines may be shown
  multiline_threshold = 2, -- collapse multi-line signatures above this many lines
}
