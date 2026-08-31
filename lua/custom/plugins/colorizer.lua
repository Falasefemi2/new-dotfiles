vim.pack.add { 'https://github.com/NvChad/nvim-colorizer.lua' }
-- Defer 33ms colorizer.config past startup - only needed for color filetypes
vim.api.nvim_create_autocmd({ 'BufReadPre', 'BufNewFile' }, {
  group = vim.api.nvim_create_augroup('lazy-colorizer', { clear = true }),
  once = true,
  callback = function()
    require('colorizer').setup {}
    -- Attach to already-open buffer if it has color
    pcall(vim.cmd, 'ColorizerAttachToBuffer')
  end,
})
