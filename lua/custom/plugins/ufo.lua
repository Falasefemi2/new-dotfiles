vim.pack.add { 'https://github.com/kevinhwang91/nvim-ufo' }
vim.pack.add { 'https://github.com/kevinhwang91/promise-async' }

vim.o.foldcolumn = '1'
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true

require('ufo').setup {
  provider_selector = function()
    return { 'treesitter', 'indent' }
  end,
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

vim.keymap.set('n', 'zR', require('ufo').openAllFolds, { desc = 'Open all folds' })
vim.keymap.set('n', 'zM', require('ufo').closeAllFolds, { desc = 'Close all folds' })
vim.keymap.set('n', 'zK', require('ufo').peekFoldedLinesUnderCursor, { desc = 'Peek fold' })
