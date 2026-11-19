vim.pack.add {
  'https://github.com/sergei-durkin/statuscoolumn.nvim',
}

---Read a live highlight attribute so the column follows the active colorscheme
---instead of staying pinned to Catppuccin mocha.
---@param group string
---@param attribute 'fg'|'bg'
---@param fallback? string
---@return string|nil
local function color(group, attribute, fallback)
  local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
  return hl[attribute] and ('#%06x'):format(hl[attribute]) or fallback
end

local function theme_colors()
  local added = color('GitSignsAdd', 'fg', color('DiagnosticOk', 'fg', '#a6e3a1'))
  local modified = color('GitSignsChange', 'fg', color('DiagnosticWarn', 'fg', '#f9e2af'))
  local removed = color('GitSignsDelete', 'fg', color('DiagnosticError', 'fg', '#f38ba8'))

  return {
    -- No fallback: themes without a CursorLine bg should not get a dark bar.
    cursorline = { bg = color('CursorLine', 'bg') },
    number = {
      normal = color('LineNr', 'fg', '#6c7086'),
      accent = color('CursorLineNr', 'fg', '#cdd6f4'),
    },

    diagnostics = {
      error = color('DiagnosticSignError', 'fg', color('DiagnosticError', 'fg', '#f38ba8')),
      warning = color('DiagnosticSignWarn', 'fg', color('DiagnosticWarn', 'fg', '#f9e2af')),
      info = color('DiagnosticSignInfo', 'fg', color('DiagnosticInfo', 'fg', '#89dceb')),
      hint = color('DiagnosticSignHint', 'fg', color('DiagnosticHint', 'fg', '#a6e3a1')),
    },

    git = {
      added = added,
      modified = modified,
      removed = removed,
    },

    git_staged = {
      added = color('GitSignsStagedAdd', 'fg', added),
      modified = color('GitSignsStagedChange', 'fg', modified),
      removed = color('GitSignsStagedDelete', 'fg', removed),
    },
  }
end

-- Defer setup past first render (VimEnter + schedule), same pattern as lualine.
vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('lazy-statuscolumn', { clear = true }),
  callback = function()
    vim.schedule(function()
      local statuscolumn = require 'statuscoolumn'
      statuscolumn.setup {
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
      }

      -- Replace the plugin's Catppuccin defaults wholesale: setup deep-merges,
      -- which would keep its CursorLine bg even when the theme has none.
      statuscolumn.config.colors = theme_colors()
      statuscolumn.setHl()

      -- The plugin re-applies its own palette on ColorScheme. This handler is
      -- registered after setup, so it recomputes from the new theme and wins.
      vim.api.nvim_create_autocmd('ColorScheme', {
        group = vim.api.nvim_create_augroup('statuscolumn-theme', { clear = true }),
        callback = function()
          statuscolumn.config.colors = theme_colors()
          statuscolumn.setHl()
        end,
      })
    end)
  end,
})
