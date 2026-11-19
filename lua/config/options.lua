-- lua/config/options.lua
-- Centralized Neovim options (extracted from init.lua:106-177 for maintainability)

vim.g.have_nerd_font = true
vim.o.termguicolors = true
-- Disable unused runtime plugins (save ~20ms netrw+matchit)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_matchit = 1
-- matchparen stays enabled (do not set loaded_matchparen) for % matching

vim.o.number = true
-- vim.o.relativenumber = true
vim.o.mouse = 'a'
vim.o.showmode = false
vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)
vim.o.breakindent = true
vim.o.undofile = true
vim.o.swapfile = false
-- Persist undo on Windows (undofile needs a directory)
local undodir = vim.fn.stdpath 'data' .. '/undo'
if vim.fn.isdirectory(undodir) == 0 then vim.fn.mkdir(undodir, 'p') end
vim.o.undodir = undodir

vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = 'yes'
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.o.inccommand = 'split'
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.confirm = true
vim.o.cmdheight = 0

-- Diagnostics UI (moved from init.lua:186-212 for discoverability)
--
-- Glyphs live in `signs.text`: Neovim >= 0.10 renders diagnostics as extmark
-- signs, so the old `sign_define` override was silently ignored and the gutter
-- fell back to "E "/"W ". Keeping them here also matches the statusline and
-- statuscolumn icons.
local diagnostic_signs = {
  [vim.diagnostic.severity.ERROR] = '󰅚 ',
  [vim.diagnostic.severity.WARN] = '󰀦 ',
  [vim.diagnostic.severity.INFO] = '󰋽 ',
  [vim.diagnostic.severity.HINT] = '󰌶 ',
}

vim.diagnostic.config {
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = { min = vim.diagnostic.severity.WARN } },
  virtual_text = true,
  virtual_lines = false,
  signs = { text = diagnostic_signs },
  jump = {
    on_jump = function(_, bufnr) vim.diagnostic.open_float { bufnr = bufnr, scope = 'cursor', focus = false } end,
  },
}
