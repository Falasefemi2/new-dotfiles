-- lua/custom/snippets/latex.lua
-- LaTeX snippets for LuaSnip. Loaded lazily on first InsertEnter (see the
-- blink/LuaSnip setup in init.lua) so there is zero startup cost.
-- Complete via blink.cmp snippet source, jump with <tab>/<s-tab>.

local ok, ls = pcall(require, 'luasnip')
if not ok then return end

local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

local function mirror(args) return args[1] end

local snippets = {
  s('doc', {
    t { '\\documentclass[' },
    i(1, '11pt'),
    t { ']{' },
    i(2, 'article'),
    t { '}', '\\usepackage{amsmath}' },
    t { '', '\\begin{document}', '  ' },
    i(3),
    t { '', '\\end{document}' },
  }),
  s('beg', {
    t '\\begin{',
    i(1, 'env'),
    t { '}', '  ' },
    i(2),
    t { '', '\\end{' },
    f(mirror, { 1 }),
    t '}',
  }),
  s('mk', { t '$', i(1), t '$' }),
  s('dm', { t { '\\[', '  ' }, i(1), t { '', '\\]' } }),
  s('eq', {
    t '\\begin{equation}\\label{eq:',
    i(1, 'label'),
    t { '}', '  ' },
    i(2),
    t { '', '\\end{equation}' },
  }),
  s('frac', { t '\\frac{', i(1), t '}{', i(2), t '}' }),
  s('fig', {
    t { '\\begin{figure}[htbp]', '  \\centering', '  \\includegraphics[width=' },
    i(1, '0.8\\textwidth'),
    t ']{',
    i(2, 'file'),
    t { '}', '  \\caption{' },
    i(3, 'caption'),
    t('}', '  \\label{fig:'),
    i(4, 'label'),
    t { '}', '\\end{figure}' },
  }),
  s('tbl', {
    t { '\\begin{table}[htbp]', '  \\centering', '  \\begin{tabular}{' },
    i(1, 'lcc'),
    t { '}', '    \\hline', '    ' },
    i(2, 'a & b \\\\'),
    t { '', '    \\hline', '  \\end{tabular}', '  \\caption{' },
    i(3, 'caption'),
    t('}', '  \\label{tab:'),
    i(4, 'label'),
    t { '}', '\\end{table}' },
  }),
  s('item', { t { '\\begin{itemize}', '  \\item ' }, i(1), t { '', '\\end{itemize}' } }),
  s('enum', { t { '\\begin{enumerate}', '  \\item ' }, i(1), t { '', '\\end{enumerate}' } }),
  s('sec', { t '\\section{', i(1), t '}' }),
  s('sub', { t '\\subsection{', i(1), t '}' }),
  s('subsub', { t '\\subsubsection{', i(1), t '}' }),
  s('pkg', { t '\\usepackage{', i(1), t '}' }),
  s('cite', { t '\\cite{', i(1), t '}' }),
  s('ref', { t '\\ref{', i(1), t '}' }),
  s('lab', { t '\\label{', i(1), t '}' }),
  s('tbf', { t '\\textbf{', i(1), t '}' }),
  s('tit', { t '\\textit{', i(1), t '}' }),
  s('href', { t '\\href{', i(1, 'url'), t '}{', i(2, 'text'), t '}' }),
}

ls.add_snippets('tex', snippets)
ls.add_snippets('plaintex', snippets)
