-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

-- Explicit plugin manifest (senior OSS: fail-loud, deterministic load order)
-- Adding a new file here requires adding one line - no magic, no silent swallow.
local plugins = {
  'color-terminal',
  'colorizer',
  'dashboard',
  'diff',
  'effect-tsgo',
  'flash',
  'go',
  'lualine',
  'markdown-preview',
  'noice',
  'pretty-ts-errors',
  'python',
  'search-replace',
  'session',
  'smear-cursor',
  'statuscolumn',
  'toggleterm',
  'trouble',
  'ufo',
  'wakatime',
}

for _, name in ipairs(plugins) do
  local ok, err = pcall(require, 'custom.plugins.' .. name)
  if not ok then vim.notify(('Failed to load custom.plugins.%s: %s'):format(name, err), vim.log.levels.ERROR) end
end
