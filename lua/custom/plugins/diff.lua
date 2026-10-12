-- diffview.nvim configuration (package is added in main config)

-- Lazy: `require('diffview')` costs ~130ms and is only needed when a diff
-- UI actually opens. Defer past first render; setup runs before any
-- Neogit/Diffview buffer can exist (both open after startup).
vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('lazy-diffview', { clear = true }),
  callback = function()
    vim.schedule(function()
      pcall(function()
        require('diffview').setup {
          enhanced_diff_hl = true,
          use_icons = vim.g.have_nerd_font,
        }
      end)
    end)
  end,
})
