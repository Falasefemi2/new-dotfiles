vim.pack.add { 'https://github.com/folke/trouble.nvim' }

local _trouble_setup = false
local function ensure_trouble(cmd)
  if not _trouble_setup then
    _trouble_setup = true
    require('trouble').setup {}
  end
  vim.cmd(cmd)
end

-- Keymaps (setup deferred until first use)
vim.keymap.set('n', '<leader>xx', function() ensure_trouble 'Trouble diagnostics toggle' end, { desc = 'Diagnostics (Trouble)' })
vim.keymap.set('n', '<leader>xX', function() ensure_trouble 'Trouble diagnostics toggle filter.buf=0' end, { desc = 'Buffer Diagnostics (Trouble)' })
vim.keymap.set('n', '<leader>cs', function() ensure_trouble 'Trouble symbols toggle focus=false' end, { desc = 'Symbols (Trouble)' })
vim.keymap.set(
  'n',
  '<leader>cr',
  function() ensure_trouble 'Trouble lsp toggle focus=false win.position=right' end,
  { desc = 'LSP Definitions / references / ... (Trouble)' }
)
vim.keymap.set('n', '<leader>xL', function() ensure_trouble 'Trouble loclist toggle' end, { desc = 'Location List (Trouble)' })
vim.keymap.set('n', '<leader>xQ', function() ensure_trouble 'Trouble qflist toggle' end, { desc = 'Quickfix List (Trouble)' })
