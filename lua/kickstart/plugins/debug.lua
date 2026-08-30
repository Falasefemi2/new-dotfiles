-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

vim.pack.add {
  'https://github.com/mfussenegger/nvim-dap',
  'https://github.com/rcarriga/nvim-dap-ui',
  'https://github.com/nvim-neotest/nvim-nio',
  'https://github.com/mason-org/mason.nvim',
  'https://github.com/jay-babu/mason-nvim-dap.nvim',
  'https://github.com/leoluz/nvim-dap-go',
  'https://github.com/mfussenegger/nvim-dap-python',
}

-- Basic debugging keymaps
vim.keymap.set('n', '<F5>', function() require('dap').continue() end, { desc = 'Debug: Start/Continue' })
vim.keymap.set('n', '<F1>', function() require('dap').step_into() end, { desc = 'Debug: Step Into' })
vim.keymap.set('n', '<F2>', function() require('dap').step_over() end, { desc = 'Debug: Step Over' })
vim.keymap.set('n', '<F3>', function() require('dap').step_out() end, { desc = 'Debug: Step Out' })
vim.keymap.set('n', '<F6>', function() require('dap').terminate() end, { desc = 'Debug: Terminate' })
vim.keymap.set('n', '<leader>db', function() require('dap').toggle_breakpoint() end, { desc = 'Debug: Toggle [B]reakpoint' })
vim.keymap.set(
  'n',
  '<leader>dB',
  function() require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ') end,
  { desc = 'Debug: Set [B]reakpoint (conditional)' }
)
vim.keymap.set('n', '<leader>dl', function() require('dap').set_breakpoint(nil, nil, vim.fn.input 'Log point message: ') end, { desc = 'Debug: Log point' })
vim.keymap.set('n', '<leader>dr', function() require('dap').repl.open() end, { desc = 'Debug: REPL' })
vim.keymap.set('n', '<leader>du', function() require('dapui').toggle() end, { desc = 'Debug: Toggle UI' })
vim.keymap.set({ 'n', 'v' }, '<leader>de', function() require('dapui').eval() end, { desc = 'Debug: Eval' })
vim.keymap.set('n', '<F7>', function() require('dapui').toggle() end, { desc = 'Debug: See last session result.' })

local dap = require 'dap'
local dapui = require 'dapui'

-- Trace logging for Windows delve issues: :help dap.set_log_level -> %LOCALAPPDATA%\nvim-data\..\cache\nvim\dap.log
dap.set_log_level 'TRACE'

require('mason-nvim-dap').setup {
  automatic_installation = true,
  handlers = {},
  ensure_installed = {
    'delve', -- Go
    'python', -- debugpy (Python)
    'js', -- js-debug-adapter (TS/JS)
  },
}

-- Dap UI setup
-- For more information, see |:help nvim-dap-ui|
---@diagnostic disable-next-line: missing-fields
dapui.setup {
  -- Set icons to characters that are more likely to work in every terminal.
  --    Feel free to remove or use ones that you like more! :)
  --    Don't feel like these are good choices.
  icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
  ---@diagnostic disable-next-line: missing-fields
  controls = {
    icons = {
      pause = '⏸',
      play = '▶',
      step_into = '⏎',
      step_over = '⏭',
      step_out = '⏮',
      step_back = 'b',
      run_last = '▶▶',
      terminate = '⏹',
      disconnect = '⏏',
    },
  },
}

-- Change breakpoint icons
vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })
vim.api.nvim_set_hl(0, 'DapStop', { fg = '#ffcc00' })
local breakpoint_icons = vim.g.have_nerd_font
    and { Breakpoint = '', BreakpointCondition = '', BreakpointRejected = '', LogPoint = '', Stopped = '' }
  or { Breakpoint = '●', BreakpointCondition = '⊜', BreakpointRejected = '⊘', LogPoint = '◆', Stopped = '⭔' }
for type, icon in pairs(breakpoint_icons) do
  local tp = 'Dap' .. type
  local hl = (type == 'Stopped') and 'DapStop' or 'DapBreak'
  vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
end

dap.listeners.after.event_initialized['dapui_config'] = dapui.open
dap.listeners.before.event_terminated['dapui_config'] = dapui.close
dap.listeners.before.event_exited['dapui_config'] = dapui.close

-- Golang (delve) - via nvim-dap-go
-- On Windows avoid dlv.CMD wrapper (slow, causes "adapter didn't respond")
local delve_path = vim.fn.exepath 'dlv'
if vim.fn.has 'win32' == 1 then
  local direct = vim.fn.stdpath 'data' .. '/mason/packages/delve/dlv.exe'
  if vim.fn.filereadable(direct) == 1 then delve_path = direct end
end
require('dap-go').setup {
  delve = {
    path = delve_path,
    -- On Windows delve must be run attached or it crashes.
    detached = vim.fn.has 'win32' == 0,
    -- Increase init timeout for slow Windows Defender scans
    build_flags = '',
  },
}

-- Python (debugpy) - respects venv from lua/custom/plugins/python.lua
pcall(function()
  local py = require 'custom.plugins.python'
  local venv_py = py and py.find_python_venv and py.find_python_venv() or nil
  -- mason debugpy path as fallback
  local mason_py = vim.fn.stdpath 'data' .. '/mason/packages/debugpy/venv/Scripts/python.exe'
  if vim.fn.has 'win32' == 0 then mason_py = vim.fn.stdpath 'data' .. '/mason/packages/debugpy/venv/bin/python' end
  local python_path = venv_py or (vim.fn.executable(mason_py) == 1 and mason_py or 'python')
  require('dap-python').setup(python_path)
end)

-- JS/TS (js-debug-adapter) - Node, Chrome, etc.
pcall(function()
  local dap = require 'dap'
  -- mason js-debug-adapter location (cross-platform)
  local js_debug = vim.fn.stdpath 'data' .. '/mason/packages/js-debug-adapter'
  local cmd = js_debug .. '/js-debug/src/dapDebugServer.js'
  -- Windows: js-debug is unpacked via mason, use js-debug-adapter directly if available
  if vim.fn.executable(js_debug .. '/js-debug-adapter') == 1 then
    -- mason v2 layout
    dap.adapters['pwa-node'] = {
      type = 'server',
      host = 'localhost',
      port = '${port}',
      executable = { command = 'node', args = { js_debug .. '/js-debug/src/dapDebugServer.js', '${port}' } },
    }
  elseif vim.fn.filereadable(cmd) == 1 then
    dap.adapters['pwa-node'] = {
      type = 'server',
      host = 'localhost',
      port = '${port}',
      executable = { command = 'node', args = { cmd, '${port}' } },
    }
  else
    -- Fallback: try mason bin js-debug-adapter (mason-nvim-dap may have created it)
    local bin = vim.fn.stdpath 'data' .. '/mason/bin/js-debug-adapter'
    if vim.fn.executable(bin) == 1 then
      dap.adapters['pwa-node'] = {
        type = 'server',
        host = 'localhost',
        port = '${port}',
        executable = { command = 'node', args = { bin, '${port}' } },
      }
    end
  end

  -- Reuse pwa-node for other JS runtimes
  for _, adapter in ipairs { 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost' } do
    if not dap.adapters[adapter] and dap.adapters['pwa-node'] then dap.adapters[adapter] = dap.adapters['pwa-node'] end
  end

  -- DAP configurations if not already set by a plugin
  for _, lang in ipairs { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact' } do
    if not dap.configurations[lang] then
      dap.configurations[lang] = {
        {
          type = 'pwa-node',
          request = 'launch',
          name = 'Launch file',
          program = '${file}',
          cwd = '${workspaceFolder}',
        },
        {
          type = 'pwa-node',
          request = 'attach',
          name = 'Attach',
          processId = require('dap.utils').pick_process,
          cwd = '${workspaceFolder}',
        },
        {
          type = 'pwa-node',
          request = 'launch',
          name = 'Launch via npm',
          runtimeExecutable = 'npm',
          runtimeArgs = { 'run', 'dev' },
          cwd = '${workspaceFolder}',
          console = 'integratedTerminal',
        },
      }
    end
  end
end)
