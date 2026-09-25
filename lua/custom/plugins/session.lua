vim.pack.add { 'https://github.com/folke/persistence.nvim' }

-- This version of persistence.nvim (see lua/persistence/config.lua) only supports
-- {dir, need, branch}. It fires User PersistenceSavePre/Post, NOT pre_save.
-- We hook PersistenceSavePre to wipe neo-tree before :mksession.
vim.o.sessionoptions = 'buffers,curdir,tabpages,winsize,help,globals,skiprtp,folds'

require('persistence').setup {
  dir = vim.fn.stdpath 'data' .. '/session/',
  need = 1,
  branch = true,
}

vim.api.nvim_create_autocmd('User', {
  pattern = 'PersistenceSavePre',
  group = vim.api.nvim_create_augroup('persistence-neotree-fix', { clear = true }),
  callback = function()
    pcall(vim.cmd, 'Neotree close')
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      local ok_ft, ft = pcall(function() return vim.bo[buf].filetype end)
      local name = vim.api.nvim_buf_get_name(buf)
      local is_neotree = (ok_ft and ft == 'neo-tree') or name:match 'neo%-tree' ~= nil
      if is_neotree then pcall(vim.api.nvim_buf_delete, buf, { force = true }) end
    end
  end,
})

-- Restore the last session automatically on startup (if no arguments were passed).
-- Session wins over dashboard: dashboard draws first on VimEnter, then we
-- load the session and wipe any leftover dashboard buffers.
vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('session-restore', { clear = true }),
  nested = true,
  callback = function()
    if vim.fn.argc(-1) == 0 and not vim.g.started_with_stdin then
      vim.schedule(function()
        local ok = pcall(function() return require('persistence').load() end)
        if ok then
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            local ok_ft, ft = pcall(function() return vim.bo[buf].filetype end)
            if ok_ft and (ft == 'dashboard' or ft == 'snacks_dashboard') then pcall(vim.api.nvim_buf_delete, buf, { force = true }) end
          end
        end
      end)
    end
  end,
})

-- Session keymaps
vim.keymap.set('n', '<leader>Ss', function() require('persistence').save() end, { desc = '[S]ession [S]ave' })
vim.keymap.set('n', '<leader>Sl', function() require('persistence').load() end, { desc = '[S]ession [L]oad' })
vim.keymap.set('n', '<leader>Sd', function() require('persistence').stop() end, { desc = "[S]ession [D]on't save" })
vim.keymap.set('n', '<leader>SS', function() require('persistence').select() end, { desc = '[S]ession [S]elect (picker)' })
