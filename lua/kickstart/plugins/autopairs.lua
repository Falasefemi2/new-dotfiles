-- autopairs
-- https://github.com/windwp/nvim-autopairs

vim.pack.add { 'https://github.com/windwp/nvim-autopairs' }

-- Lazy: autopairs only matters once you start typing.
vim.api.nvim_create_autocmd('InsertEnter', {
  group = vim.api.nvim_create_augroup('lazy-autopairs', { clear = true }),
  once = true,
  callback = function() require('nvim-autopairs').setup {} end,
})
