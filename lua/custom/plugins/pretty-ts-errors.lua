vim.pack.add { 'https://github.com/youyoumu/pretty-ts-errors.nvim' }

-- Defer setup past first render (VimEnter + schedule), same pattern as lualine.
vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('lazy-pretty-ts-errors', { clear = true }),
  callback = function()
    vim.schedule(function() require('pretty-ts-errors').setup {} end)
  end,
})

-- pretty-ts-errors only understands ts_ls; Effect projects run effect_tsgo.
local function use_ts_pretty(fn)
  return function()
    for _, c in ipairs(vim.lsp.get_clients { bufnr = 0 }) do
      if c.name == 'effect_tsgo' then
        vim.notify('pretty-ts-errors is ts_ls-only; showing diagnostic float instead', vim.log.levels.INFO)
        vim.diagnostic.open_float { scope = 'cursor', focus = false }
        return
      end
    end
    fn()
  end
end

vim.keymap.set('n', '<leader>ce', use_ts_pretty(function() require('pretty-ts-errors').show_formatted_error() end), { desc = 'Show TS error' })
vim.keymap.set('n', '<leader>cE', use_ts_pretty(function() require('pretty-ts-errors').open_all_errors() end), { desc = 'Show all TS errors' })
vim.keymap.set('n', '<leader>ct', function() require('pretty-ts-errors').toggle_auto_open() end, { desc = 'Toggle TS error auto-display' })
