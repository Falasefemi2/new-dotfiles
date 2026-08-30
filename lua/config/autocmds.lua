-- lua/config/autocmds.lua
-- Core autocommands (extracted from init.lua:248-287)

-- Highlight on yank
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

-- Auto-create parent directories when saving (skip remote URIs like oil://, fugitive://)
vim.api.nvim_create_autocmd('BufWritePre', {
  desc = 'Auto-create parent directories when saving',
  group = vim.api.nvim_create_augroup('kickstart-auto-create-dir', { clear = true }),
  callback = function(event)
    if event.match:match('^%w%w+:[\\/][\\/]') then return end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ':h'), 'p')
  end,
})

-- Equalize splits on VimResized
vim.api.nvim_create_autocmd('VimResized', {
  desc = 'Equalize splits on window resize',
  group = vim.api.nvim_create_augroup('kickstart-resize-splits', { clear = true }),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd('tabdo wincmd =')
    vim.cmd('tabnext ' .. current_tab)
  end,
})

-- Close utility windows with q + make them unlisted
vim.api.nvim_create_autocmd('FileType', {
  desc = 'Close utility windows with q',
  group = vim.api.nvim_create_augroup('kickstart-close-with-q', { clear = true }),
  pattern = { 'help', 'lspinfo', 'man', 'notify', 'qf', 'query', 'spectre_panel', 'startuptime' },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set('n', 'q', '<cmd>close<CR>', { buffer = event.buf, silent = true, desc = 'Close buffer' })
  end,
})
