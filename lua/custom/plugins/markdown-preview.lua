-- markdown-preview.nvim: lazy-load on markdown buffers or first use.
-- The plugin ships its own :MarkdownPreviewToggle; we must NOT define a
-- user command with the same name (it would shadow the plugin command and
-- recurse into itself). Instead we ensure the plugin is on the runtimepath
-- and then invoke the real plugin command.
vim.pack.add { 'https://github.com/iamcco/markdown-preview.nvim' }

local _mkdp_loaded = false
local function load_mkdp()
  if _mkdp_loaded then return end
  _mkdp_loaded = true
  vim.cmd.packadd 'markdown-preview.nvim'
end

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  group = vim.api.nvim_create_augroup('lazy-mkdp', { clear = true }),
  once = true,
  callback = load_mkdp,
})

vim.keymap.set('n', '<leader>mp', function()
  load_mkdp()
  vim.cmd 'MarkdownPreviewToggle'
end, { desc = '[M]arkdown [P]review toggle' })
