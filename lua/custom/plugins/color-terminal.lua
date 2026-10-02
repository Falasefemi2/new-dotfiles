vim.pack.add { 'https://github.com/nvim-zh/colorful-winsep.nvim' }

-- Defer setup past first render (VimEnter + schedule), same pattern as lualine.
vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('lazy-colorful-winsep', { clear = true }),
  callback = function()
    vim.schedule(
      function()
        require('colorful-winsep').setup {
          border = 'bold',
          excluded_ft = { 'TelescopePrompt', 'mason' },
          animate = {
            enabled = 'shift',
            shift = {
              delay = 16,
              frames = 15,
              easing = 'ease_out_cubic',
            },
          },
        }
      end
    )
  end,
})
