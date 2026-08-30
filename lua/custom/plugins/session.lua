vim.pack.add { 'https://github.com/folke/persistence.nvim' }

require('persistence').setup {
  dir = vim.fn.stdpath 'data' .. '/session/',
  -- winpos causes stale window layout + neo-tree invalid window errors, so removed
  options = { 'buffers', 'curdir', 'tabpages', 'winsize' },
  -- Prevent neo-tree buffer from being persisted.
  -- That `badd +0 neo-tree filesystem [1]` line in session files is what causes:
  --   E95: Buffer with this name already exists
  --   Invalid 'window': Expected Lua number (neo-tree-follow on stale window)
  pre_save = function()
    -- Close neo-tree UI first
    pcall(vim.cmd, 'Neotree close')
    -- Force-wipe any remaining neo-tree buffers that would still be saved via :mksession
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      local name = vim.api.nvim_buf_get_name(buf)
      if name:match('neo%-tree') then pcall(vim.api.nvim_buf_delete, buf, { force = true }) end
    end
  end,
  post_save = nil,
  save_empty_session = false,
}

-- Restore the last session automatically on startup (if no arguments were passed)
vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('session-restore', { clear = true }),
  nested = true,
  callback = function()
    if vim.fn.argc(-1) == 0 and not vim.g.started_with_stdin then
      -- Use vim.schedule + nested=true so :source session happens after
      -- dashboard/neo-tree VimEnter setup. persistence.load() is no-op if no
      -- session file exists for cwd (checks filereadable internally).
      vim.schedule(function() require('persistence').load() end)
    end
  end,
})

-- Session keymaps
vim.keymap.set('n', '<leader>Ss', function() require('persistence').save() end, { desc = '[S]ession [S]ave' })
vim.keymap.set('n', '<leader>Sl', function() require('persistence').load() end, { desc = '[S]ession [L]oad' })
vim.keymap.set('n', '<leader>Sd', function() require('persistence').stop() end, { desc = '[S]ession [D]on\'t save' })
vim.keymap.set('n', '<leader>SS', function() require('persistence').select() end, { desc = '[S]ession [S]elect (picker)' })
