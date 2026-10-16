-- render-markdown.lua
-- Renders Markdown in-place (headings, tables, callouts, checkboxes, code
-- blocks, LaTeX) so READMEs and docs are readable without leaving the buffer.
-- Complements <leader>mp (browser preview).
-- https://github.com/MeanderingProgrammer/render-markdown.nvim
vim.pack.add { 'https://github.com/MeanderingProgrammer/render-markdown.nvim' }

require('render-markdown').setup {}
