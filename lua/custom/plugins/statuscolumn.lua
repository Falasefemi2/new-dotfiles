vim.pack.add {
  'https://github.com/sergei-durkin/statuscoolumn.nvim',
}

-- Defer setup past first render (VimEnter + schedule), same pattern as lualine.
vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('lazy-statuscolumn', { clear = true }),
  callback = function()
    vim.schedule(function()
      require('statuscoolumn').setup {
        number = {
          type = 'hybrid',
        },

        git = {
          enabled = true,
        },

        border = {
          enabled = true,
          text = '│',
        },

        fold = {
          enabled = true,
          text = {
            opened = '',
            closed = '',
            scope = ' ',
          },
        },

        colors = {
          -- Catppuccin mocha (matches the active colourscheme)
          cursorline = { bg = '#313244' }, -- surface0
          number = {
            normal = '#6c7086', -- overlay0 (LineNr)
            accent = '#cdd6f4', -- text (CursorLineNr)
          },

          diagnostics = {
            error = '#f38ba8',
            warning = '#f9e2af',
            info = '#89dceb',
            hint = '#a6e3a1',
          },

          git = {
            added = '#a6e3a1',
            modified = '#f9e2af',
            removed = '#f38ba8',
          },

          git_staged = {
            added = '#5c8a60',
            modified = '#8a7a45',
            removed = '#8a4a52',
          },
        },
      }
    end)
  end,
})
