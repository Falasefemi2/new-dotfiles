vim.pack.add {
  { src = 'https://github.com/iamcco/markdown-preview.nvim', build = 'cd app && npm install' },
}

vim.keymap.set('n', '<leader>mp', '<cmd>MarkdownPreviewToggle<CR>', { desc = '[M]arkdown [P]review toggle' })
