vim.pack.add { 'https://github.com/kevinhwang91/nvim-ufo' }
vim.pack.add { 'https://github.com/kevinhwang91/promise-async' }

-- Defer setup ~34ms past first render (VimEnter + schedule), same pattern as
-- lualine/noice. Keymaps lazy-require so ufo is never loaded at startup.
vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('lazy-ufo', { clear = true }),
  callback = function()
    vim.schedule(function()
      vim.o.foldcolumn = '1'
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true

      require('ufo').setup {
        provider_selector = function() return { 'treesitter', 'indent' } end,
        close_fold_kinds_for_ft = {
          default = { 'imports', 'comment' },
        },
        preview = {
          win_config = {
            border = 'rounded',
            winhighlight = 'Normal:Folded',
            winblend = 0,
          },
          mappings = {
            scrollU = '<C-u>',
            scrollD = '<C-d>',
            jumpTop = '[',
            jumpBot = ']',
          },
        },
      }
    end)
  end,
})

vim.keymap.set('n', 'zR', function() require('ufo').openAllFolds() end, { desc = 'Open all folds' })
vim.keymap.set('n', 'zM', function() require('ufo').closeAllFolds() end, { desc = 'Close all folds' })
vim.keymap.set('n', 'zK', function() require('ufo').peekFoldedLinesUnderCursor() end, { desc = 'Peek fold' })
