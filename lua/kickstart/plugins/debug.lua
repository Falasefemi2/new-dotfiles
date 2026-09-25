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

-- Lazy DAP setup - saves 118ms mason-nvim-dap + 64ms debug at startup
-- Heavy requires deferred until first debug key (F5, <leader>db, etc.)
local _dap_ready = false
local function ensure_dap()
  if _dap_ready then return require 'dap', require 'dapui' end
  _dap_ready = true
  local dap = require 'dap'
  local dapui = require 'dapui'
  require('mason-nvim-dap').setup {
    automatic_installation = true,
    handlers = {},
    ensure_installed = { 'delve', 'python', 'js' },
  }
  ---@diagnostic disable-next-line: missing-fields
  dapui.setup {
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
  vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#f38ba8' })
  vim.api.nvim_set_hl(0, 'DapStop', { fg = '#f9e2af' })
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
  -- Prefer the real mason delve binary over the PATH shim (dlv.cmd on
  -- Windows can break `dlv dap`). Falls back to exepath when missing.
  local delve_path = vim.fn.exepath 'dlv'
  local mason_delve = vim.fn.stdpath 'data' .. '/mason/packages/delve/dlv'
  if vim.fn.has 'win32' == 1 then mason_delve = mason_delve .. '.exe' end
  if vim.fn.executable(mason_delve) == 1 then
    delve_path = mason_delve
  elseif vim.fn.has 'win32' == 1 then
    local direct = vim.fn.stdpath 'data' .. '/mason/packages/delve/dlv.exe'
    if vim.fn.filereadable(direct) == 1 then delve_path = direct end
  end
  require('dap-go').setup { delve = { path = delve_path, detached = vim.fn.has 'win32' == 0, build_flags = '' } }
  pcall(function()
    local py = require 'custom.plugins.python'
    local venv_py = py and py.find_python_venv and py.find_python_venv() or nil
    local mason_py = vim.fn.stdpath 'data' .. '/mason/packages/debugpy/venv/Scripts/python.exe'
    if vim.fn.has 'win32' == 0 then mason_py = vim.fn.stdpath 'data' .. '/mason/packages/debugpy/venv/bin/python' end
    local python_path = venv_py or (vim.fn.executable(mason_py) == 1 and mason_py or 'python')
    require('dap-python').setup(python_path)
  end)
  -- JS/TS (deferred, was 5ms at startup)
  pcall(function()
    local dap2 = require 'dap'
    local js_debug = vim.fn.stdpath 'data' .. '/mason/packages/js-debug-adapter'
    local cmd = js_debug .. '/js-debug/src/dapDebugServer.js'
    if vim.fn.executable(js_debug .. '/js-debug-adapter') == 1 then
      dap2.adapters['pwa-node'] = {
        type = 'server',
        host = '127.0.0.1',
        port = '${port}',
        executable = { command = 'node', args = { js_debug .. '/js-debug/src/dapDebugServer.js', '${port}', '127.0.0.1' } },
      }
    elseif vim.fn.filereadable(cmd) == 1 then
      dap2.adapters['pwa-node'] = { type = 'server', host = '127.0.0.1', port = '${port}', executable = { command = 'node', args = { cmd, '${port}', '127.0.0.1' } } }
    else
      local bin = vim.fn.stdpath 'data' .. '/mason/bin/js-debug-adapter'
      if vim.fn.has 'win32' == 1 then
        local win_bin = bin .. '.cmd'
        if vim.fn.executable(win_bin) == 1 then
          dap2.adapters['pwa-node'] = { type = 'server', host = 'localhost', port = '${port}', executable = { command = win_bin, args = { '${port}' } } }
        end
      end
      if not dap2.adapters['pwa-node'] and vim.fn.executable(bin) == 1 then
        dap2.adapters['pwa-node'] = { type = 'server', host = 'localhost', port = '${port}', executable = { command = 'node', args = { bin, '${port}' } } }
      end
    end
    for _, adapter in ipairs { 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost' } do
      if not dap2.adapters[adapter] and dap2.adapters['pwa-node'] then dap2.adapters[adapter] = dap2.adapters['pwa-node'] end
    end
    for _, lang in ipairs { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact' } do
      if not dap2.configurations[lang] then
        dap2.configurations[lang] = {
          { type = 'pwa-node', request = 'launch', name = 'Launch file', program = '${file}', cwd = '${workspaceFolder}' },
          { type = 'pwa-node', request = 'attach', name = 'Attach', processId = require('dap.utils').pick_process, cwd = '${workspaceFolder}' },
          {
            type = 'pwa-node',
            request = 'launch',
            name = 'Launch via npm',
            runtimeExecutable = vim.fn.has 'win32' == 1 and 'npm.cmd' or 'npm',
            runtimeArgs = { 'run', 'dev' },
            cwd = '${workspaceFolder}',
            console = 'integratedTerminal',
          },
        }
      end
    end
  end)
  return dap, dapui
end

-- Basic debugging keymaps (lazy-ensure on first use)
vim.keymap.set('n', '<F5>', function()
  ensure_dap()
  require('dap').continue()
end, { desc = 'Debug: Start/Continue' })
vim.keymap.set('n', '<F1>', function()
  ensure_dap()
  require('dap').step_into()
end, { desc = 'Debug: Step Into' })
vim.keymap.set('n', '<F2>', function()
  ensure_dap()
  require('dap').step_over()
end, { desc = 'Debug: Step Over' })
vim.keymap.set('n', '<F3>', function()
  ensure_dap()
  require('dap').step_out()
end, { desc = 'Debug: Step Out' })
vim.keymap.set('n', '<F6>', function()
  ensure_dap()
  require('dap').terminate()
end, { desc = 'Debug: Terminate' })
vim.keymap.set('n', '<leader>db', function()
  ensure_dap()
  require('dap').toggle_breakpoint()
end, { desc = 'Debug: Toggle [B]reakpoint' })
vim.keymap.set('n', '<leader>dB', function()
  ensure_dap()
  require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
end, { desc = 'Debug: Set [B]reakpoint (conditional)' })
vim.keymap.set('n', '<leader>dl', function()
  ensure_dap()
  require('dap').set_breakpoint(nil, nil, vim.fn.input 'Log point message: ')
end, { desc = 'Debug: Log point' })
vim.keymap.set('n', '<leader>dr', function()
  ensure_dap()
  require('dap').repl.open()
end, { desc = 'Debug: REPL' })
vim.keymap.set('n', '<leader>du', function()
  ensure_dap()
  require('dapui').toggle()
end, { desc = 'Debug: Toggle UI' })
vim.keymap.set({ 'n', 'v' }, '<leader>de', function()
  ensure_dap()
  require('dapui').eval()
end, { desc = 'Debug: Eval' })
vim.keymap.set('n', '<F7>', function()
  ensure_dap()
  require('dapui').toggle()
end, { desc = 'Debug: Toggle UI' })
-- Go test debugging via nvim-dap-go (only meaningful in Go buffers, but
-- harmless globally since dap-go errors clearly outside Go projects)
vim.keymap.set('n', '<leader>dt', function()
  ensure_dap()
  require('dap-go').debug_test()
end, { desc = 'Debug: Go [T]est (nearest)' })
vim.keymap.set('n', '<leader>dT', function()
  ensure_dap()
  require('dap-go').debug_last_test()
end, { desc = 'Debug: Go last [T]est' })
