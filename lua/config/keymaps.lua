-- lua/config/keymaps.lua
-- Core keymaps (extracted from init.lua:179-246). No plugin deps here.

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlight' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Window navigation (consistent <C-hjkl>)
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Window resizing
vim.keymap.set('n', '<C-Up>', '<cmd>resize +2<CR>', { desc = 'Increase Window Height' })
vim.keymap.set('n', '<C-Down>', '<cmd>resize -2<CR>', { desc = 'Decrease Window Height' })
vim.keymap.set('n', '<C-Left>', '<cmd>vertical resize -2<CR>', { desc = 'Decrease Window Width' })
vim.keymap.set('n', '<C-Right>', '<cmd>vertical resize +2<CR>', { desc = 'Increase Window Width' })

-- Buffer navigation (buffer group = <leader>b)
vim.keymap.set('n', '[b', '<cmd>bprevious<CR>', { desc = 'Previous Buffer' })
vim.keymap.set('n', ']b', '<cmd>bnext<CR>', { desc = 'Next Buffer' })
vim.keymap.set('n', '<leader>bd', function()
  local ok, bufremove = pcall(require, 'mini.bufremove')
  local bd = ok and bufremove.delete or function(buf, force) vim.api.nvim_buf_delete(buf, { force = force }) end
  if vim.bo.modified then
    local choice = vim.fn.confirm(('Save changes to %q?'):format(vim.fn.bufname()), '&Yes\n&No\n&Cancel')
    if choice == 1 then
      vim.cmd.write()
      bd(0, false)
    elseif choice == 2 then
      bd(0, true)
    end
  else
    bd(0, false)
  end
end, { desc = '[B]uffer [D]elete' })
