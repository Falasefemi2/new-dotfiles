-- Linting

vim.pack.add { 'https://github.com/mfussenegger/nvim-lint' }

-- Lazy: `require('lint')` at startup forces the module (and its linter
-- resolution) onto the critical path. Linters are configured on first use.
local _lint_configured = false

-- Prefer a project's own ESLint setup when present, otherwise oxlint.
-- nvim-lint has no per-linter `condition`, so we filter inside `try_lint`
-- (see `lint_filter` below): exactly one JS/TS linter runs per buffer.
local ESLINT_CONFIGS = {
  'eslint.config.js',
  'eslint.config.mjs',
  'eslint.config.cjs',
  'eslint.config.ts',
  'eslint.config.mts',
  'eslint.config.cts',
  'eslint.config.json',
  '.eslintrc',
  '.eslintrc.js',
  '.eslintrc.cjs',
  '.eslintrc.json',
  '.eslintrc.yml',
  '.eslintrc.yaml',
}
local function has_eslint_config(bufnr)
  local root = vim.fs.root(bufnr, { 'package.json', '.git' }) or vim.fn.getcwd()
  for _, name in ipairs(ESLINT_CONFIGS) do
    if vim.fn.filereadable(vim.fs.joinpath(root, name)) == 1 then return true end
  end
  return false
end

local function lint_filter(linter)
  if linter.name == 'eslint' then return has_eslint_config(0) end
  if linter.name == 'oxlint' then return not has_eslint_config(0) end
  return true
end

local function ensure_lint()
  if _lint_configured then return require 'lint' end
  _lint_configured = true
  local lint = require 'lint'
  lint.linters_by_ft = {
    markdown = { 'markdownlint' }, -- Make sure to install `markdownlint` via mason / npm
    python = { 'ruff' },
    go = { 'golangci_lint' },
    javascript = { 'oxlint', 'eslint' },
    javascriptreact = { 'oxlint', 'eslint' },
    typescript = { 'oxlint', 'eslint' },
    typescriptreact = { 'oxlint', 'eslint' },
  }
  return lint
end

-- To allow other plugins to add linters to require('lint').linters_by_ft,
-- instead set linters_by_ft like this:
-- lint.linters_by_ft = lint.linters_by_ft or {}
-- lint.linters_by_ft['markdown'] = { 'markdownlint' }
--
-- However, note that this will enable a set of default linters,
-- which will cause errors unless these tools are available:
-- {
--   clojure = { "clj-kondo" },
--   dockerfile = { "hadolint" },
--   inko = { "inko" },
--   janet = { "janet" },
--   json = { "jsonlint" },
--   markdown = { "vale" },
--   rst = { "vale" },
--   ruby = { "ruby" },
--   terraform = { "tflint" },
--   text = { "vale" }
-- }
--
-- You can disable the default linters by setting their filetypes to nil:
-- lint.linters_by_ft['clojure'] = nil
-- lint.linters_by_ft['dockerfile'] = nil
-- lint.linters_by_ft['janet'] = nil
-- lint.linters_by_ft['json'] = nil
-- lint.linters_by_ft['markdown'] = nil
-- lint.linters_by_ft['rst'] = nil
-- lint.linters_by_ft['ruby'] = nil
-- lint.linters_by_ft['terraform'] = nil
-- lint.linters_by_ft['text'] = nil

-- Create autocommand which carries out the actual linting
-- on the specified events.
local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
  group = lint_augroup,
  callback = function()
    -- Only run the linter in buffers that you can modify in order to
    -- avoid superfluous noise, notably within the handy LSP pop-ups that
    -- describe the hovered symbol using Markdown.
    if vim.bo.modifiable then
      local lint = ensure_lint()
      pcall(lint.try_lint, nil, { filter = lint_filter })
    end
  end,
})
