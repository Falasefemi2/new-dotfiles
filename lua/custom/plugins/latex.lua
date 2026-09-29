-- latex.lua
-- LaTeX development: vimtex (compile/view/forward search) + texlab LSP.
-- texlab server itself is enabled in init.lua SECTION 5 (Mason auto-installs
-- `texlab` + `latexindent`); this file owns vimtex, the PDF viewer, conceal,
-- and <leader>l keymaps. Treesitter `latex`/`bibtex` parsers are covered by
-- the FileType auto-installer + `:TSEnsure` in init.lua.

-- Globals must be set BEFORE vimtex loads, so keep them at top level (cheap,
-- no startup cost). The plugin itself lazy-loads on first TeX buffer.
vim.g.tex_flavor = 'latex'
vim.g.vimtex_mappings_enabled = 1 -- keep default <localleader>l maps; ours live under <leader>l
vim.g.vimtex_indent_enabled = 1
vim.g.vimtex_syntax_enabled = 1
vim.g.vimtex_quickfix_mode = 0 -- stay closed; diagnostics via texlab + Trouble (<leader>xx)
vim.g.vimtex_quickfix_open_on_warning = 0
vim.g.vimtex_format_enabled = 0 -- formatting via texlab/latexindent + <leader>f, not vimtex
vim.g.vimtex_compiler_method = 'latexmk'
vim.g.vimtex_compiler_latexmk = {
  out_dir = 'build',
  options = { '-pdf', '-interaction=nonstopmode', '-synctex=1', '-file-line-error' },
}
vim.g.vimtex_toc_config = { show_help = 0, layer_status = { label = 0 } }

if vim.fn.has 'win32' == 1 then
  -- Windows: SumatraPDF gives SyncTeX forward + inverse search.
  -- Install: winget install ChristianGhimire.SumatraPDF (or strelec/SumatraPDF).
  -- Inverse search in Sumatra (Settings > Options > Set inverse search command-line):
  --   nvim --headless -c "VimtexInverseSearch %l '%f'"
  vim.g.vimtex_view_general_viewer = 'SumatraPDF'
  vim.g.vimtex_view_general_options = '-reuse-instance -forward-search @tex @line @pdf'
else
  -- Linux: zathura (needs zathura-pdf-mupdf for SyncTeX). macOS: Skim.
  -- Forward search for texlab is configured in init.lua to match (zathura).
  vim.g.vimtex_view_method = vim.fn.has 'mac' == 1 and 'skim' or 'zathura'
end

-- vim.pack.add only puts the plugin on the runtimepath; because startup has
-- already finished by the time a TeX buffer opens, its plugin/*.vim files
-- (which define :VimtexCompile etc.) are NOT sourced automatically.
-- :packadd does that. Guarded by exists() so repeated calls are harmless.
local function load_vimtex()
  if vim.fn.exists ':VimtexCompile' == 2 then return true end
  vim.pack.add { 'https://github.com/lervag/vimtex' }
  pcall(vim.cmd.packadd, 'vimtex')
  -- VimTeX creates its :Vimtex* commands per buffer from ftplugin
  -- (vimtex#init). When this runs inside a FileType autocmd that event
  -- already fired, so initialize the current buffer manually.
  local ft = vim.bo.filetype
  if (ft == 'tex' or ft == 'plaintex' or ft == 'bib') and vim.b.vimtex == nil then pcall(vim.fn['vimtex#init']) end
  return vim.fn.exists ':VimtexCompile' == 2
end

-- Conceal is buffer-local so markdown/code buffers are unaffected.
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('latex-conceal', { clear = true }),
  pattern = { 'tex', 'plaintex', 'bib' },
  callback = function() vim.opt_local.conceallevel = 2 end,
})
vim.g.tex_conceal = 'abdmg'

-- Buffer-local <leader>l keymaps (vimtex commands + texlab fallbacks).
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('latex-keymaps', { clear = true }),
  pattern = { 'tex', 'plaintex', 'bib' },
  callback = function(event)
    -- Load first: guarantees :Vimtex* commands exist before any keypress in
    -- this buffer (a separate FileType autocmd could run after the maps).
    load_vimtex()
    local buf = event.buf
    local map = function(keys, cmd, desc) vim.keymap.set('n', keys, cmd, { buffer = buf, silent = true, desc = desc }) end
    map('<leader>ll', '<cmd>VimtexCompile<CR>', '[L]aTeX compile (toggle continuous)')
    map('<leader>lv', '<cmd>VimtexView<CR>', '[L]aTeX view PDF')
    map('<leader>ls', '<cmd>VimtexView<CR>', '[L]aTeX forward search (sync)')
    map('<leader>le', '<cmd>VimtexErrors<CR>', '[L]aTeX errors/quickfix')
    map('<leader>lc', '<cmd>VimtexClean<CR>', '[L]aTeX clean aux')
    map('<leader>lk', '<cmd>VimtexStop<CR>', '[L]aTeX stop compiler')
    map('<leader>lK', '<cmd>VimtexStopAll<CR>', '[L]aTeX stop all compilers')
    map('<leader>lt', '<cmd>VimtexTocToggle<CR>', '[L]aTeX toggle ToC')
    map('<leader>li', '<cmd>VimtexInfo<CR>', '[L]aTeX info/state')
    map('<leader>lr', '<cmd>VimtexReloadState<CR>', '[L]aTeX reload state')
    -- texlab (nvim-lspconfig creates these buffer-local cmds when texlab attaches):
    -- :TexlabBuild / :TexlabForwardSearch work even if vimtex is uninstalled.
    map('<leader>lb', function()
      if vim.fn.exists ':TexlabBuild' == 2 then
        vim.cmd 'TexlabBuild'
      else
        vim.cmd 'VimtexCompile'
      end
    end, '[L]aTeX build once (texlab)')
    map('<leader>lf', function()
      if vim.fn.exists ':TexlabForwardSearch' == 2 then
        vim.cmd 'TexlabForwardSearch'
      else
        vim.cmd 'VimtexView'
      end
    end, '[L]aTeX forward search (texlab)')
  end,
})

-- Manual escape hatch (loading already happens via the FileType callback above).
vim.api.nvim_create_user_command('VimtexLoad', load_vimtex, { desc = 'Load vimtex on demand' })
