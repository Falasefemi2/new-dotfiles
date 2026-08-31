-- Defer wakatime 254ms plugin/wakatime.vim past first render (vim.pack loads plugin/ eagerly)
-- Save ~260ms on startup; wakatime still tracks after VimEnter
vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('lazy-wakatime', { clear = true }),
  callback = function()
    vim.schedule(function() vim.pack.add { 'https://github.com/wakatime/vim-wakatime' } end)
  end,
})
