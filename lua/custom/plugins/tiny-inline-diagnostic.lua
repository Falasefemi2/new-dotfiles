vim.pack.add { 'https://github.com/rachartier/tiny-inline-diagnostic.nvim' }

require('tiny-inline-diagnostic').setup {
  -- Use the classic preset for a clean appearance
  preset = 'classic',

  options = {
    -- Show every diagnostic on the cursor line, even when the cursor is not
    -- inside the exact diagnostic range.
    show_all_diags_on_cursorline = true,

    -- Keep errors visible on every line; warnings/info/hints stay on the
    -- cursor line to avoid noise.
    multilines = {
      enabled = true,
      always_show = true,
      severity = { vim.diagnostic.severity.ERROR },
    },

    -- Display the source of diagnostics (e.g., "lua_ls", "pyright")
    show_source = {
      enabled = true, -- Enable showing source names
      if_many = false, -- Only show source if multiple sources exist for the same diagnostic
    },
  },
}
-- Disable Neovim's default virtual text diagnostics to prevent conflicts
vim.diagnostic.config { virtual_text = false }
