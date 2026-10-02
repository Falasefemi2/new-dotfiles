vim.pack.add {
  'https://github.com/sphamba/smear-cursor.nvim',
}

-- Defer setup past first render (VimEnter + schedule), same pattern as lualine.
vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('lazy-smear-cursor', { clear = true }),
  callback = function()
    vim.schedule(
      function()
        require('smear_cursor').setup {
          stiffness = 0.8,
          trailing_stiffness = 0.5,
          distance_stop_animating = 0.5,
        }
      end
    )
  end,
})
