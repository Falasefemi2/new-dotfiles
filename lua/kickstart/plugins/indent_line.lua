-- Add indentation guides even on blank lines

-- Enable `lukas-reineke/indent-blankline.nvim`
-- See `:help ibl`
vim.pack.add { 'https://github.com/lukas-reineke/indent-blankline.nvim' }

-- Lazy: ibl costs ~200ms (module + setup) and only matters for real files.
vim.api.nvim_create_autocmd({ 'BufReadPre', 'BufNewFile' }, {
  group = vim.api.nvim_create_augroup('lazy-ibl', { clear = true }),
  once = true,
  callback = function() require('ibl').setup {} end,
})
