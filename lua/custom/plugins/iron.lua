-- iron.lua
-- Quick REPL interaction without leaving the work buffer.
-- https://github.com/Vigemus/iron.nvim (plugin + library)

vim.pack.add {
  'https://github.com/Vigemus/iron.nvim',
}

local iron = require 'iron.core'
local view = require 'iron.view'
local common = require 'iron.fts.common'

local is_win = vim.fn.has 'win32' == 1

-- Prefer the project's venv python when available (see custom.plugins.python),
-- otherwise fall back to python3 / python on PATH.
local function python_command()
  local ok, py = pcall(require, 'custom.plugins.python')
  if ok and py and py.find_python_venv then
    local path = py.find_python_venv(vim.fn.getcwd())
    if path and path ~= '' then return { path } end
  end
  if vim.fn.executable 'python3' == 1 then return { 'python3' } end
  return { 'python' }
end

local shell_command
if is_win then
  shell_command = { 'powershell.exe', '-NoLogo' }
elseif vim.fn.executable 'zsh' == 1 then
  shell_command = { 'zsh' }
else
  shell_command = { vim.o.shell }
end

iron.setup {
  config = {
    scratch_repl = true,
    repl_definition = {
      sh = { command = shell_command },
      powershell = { command = { 'powershell.exe', '-NoLogo' } },
      python = {
        command = python_command,
        format = common.bracketed_paste_python,
        block_dividers = { '# %%', '#%%' },
        -- Required for python3.13+ basic REPL behavior
        env = { PYTHON_BASIC_REPL = '1' },
      },
      lua = { command = { 'lua' } },
      javascript = { command = { 'node' } },
      typescript = { command = { 'ts-node' } },
      -- Example: custom REPL that loads the current file
      -- haskell = {
      --   command = function(meta)
      --     local filename = vim.api.nvim_buf_get_name(meta.current_bufnr)
      --     return { 'cabal', 'v2-repl', filename }
      --   end,
      -- },
    },
    repl_filetype = function(_, ft) return ft end,
    -- Send selections to the nvim-dap REPL when a debug session is running.
    dap_integration = true,
    repl_open_cmd = view.bottom(40),
  },
  -- NOTE: upstream iron defaults live under <space>r / <space>s, but this
  -- config already uses <leader>r for Spectre replace and <leader>s for
  -- Telescope search, so iron lives under <leader>e ([E]xecute REPL).
  keymaps = {
    toggle_repl = '<leader>et',
    restart_repl = '<leader>eR',
    send_motion = '<leader>es',
    visual_send = '<leader>es',
    send_file = '<leader>eF',
    send_line = '<leader>el',
    send_paragraph = '<leader>ep',
    send_until_cursor = '<leader>eu',
    send_mark = '<leader>eM',
    send_code_block = '<leader>eb',
    send_code_block_and_move = '<leader>en',
    mark_motion = '<leader>em',
    mark_visual = '<leader>em',
    remove_mark = '<leader>eD',
    cr = '<leader>e<cr>',
    interrupt = '<leader>e<space>',
    exit = '<leader>eq',
    clear = '<leader>eC',
  },
  highlight = { italic = true },
  ignore_blank_lines = true,
}

vim.keymap.set('n', '<leader>ef', '<cmd>IronFocus<cr>', { desc = 'REPL focus' })
vim.keymap.set('n', '<leader>eh', '<cmd>IronHide<cr>', { desc = 'REPL hide' })
