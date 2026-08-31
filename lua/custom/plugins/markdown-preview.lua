-- Lazy 33ms mkdp.vim + npm build - only on markdown or :MarkdownPreview
local function load_mkdp()
  vim.pack.add { { src = 'https://github.com/iamcco/markdown-preview.nvim', build = 'cd app && npm install' } }
  vim.keymap.set('n', '<leader>mp', '<cmd>MarkdownPreviewToggle<CR>', { desc = '[M]arkdown [P]review toggle' })
end
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  group = vim.api.nvim_create_augroup('lazy-mkdp', { clear = true }),
  once = true,
  callback = load_mkdp,
})
vim.api.nvim_create_user_command('MarkdownPreviewToggle', function()
  load_mkdp()
  vim.cmd 'MarkdownPreviewToggle'
end, {})
