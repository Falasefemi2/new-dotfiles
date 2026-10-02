-- Effect Language Service (effect-tsgo) LSP setup
--
-- @effect/tsgo ships a TypeScript-Go binary (tsc.exe) with the Effect
-- language service BUILT IN. This config starts that binary as the LSP
-- server, exactly like nvim-lspconfig's `tsgo`/`tsc` config but pointed
-- at the Effect-patched binary resolved from node_modules.
--
-- The Effect plugin is also declared in the project tsconfig.json:
--   "plugins": [{ "name": "@effect/language-service" }]

local function find_effect_tsgo_exe(root)
  if not root then return nil end
  local platform_dirs = {
    'tsgo-win32-x64',
    'tsgo-win32-arm64',
    'tsgo-linux-x64',
    'tsgo-linux-arm64',
    'tsgo-darwin-x64',
    'tsgo-darwin-arm64',
  }
  for _, dir in ipairs(platform_dirs) do
    local base = root .. '/node_modules/@effect/' .. dir
    local matches = vim.fs.find('tsc.exe', { path = base .. '/artifacts/typescript', limit = 1 })
    if matches and #matches > 0 then return matches[1] end
    matches = vim.fs.find('tsc', { path = base .. '/artifacts/typescript', limit = 1 })
    if matches and #matches > 0 then return matches[1] end
  end
  return nil
end

vim.lsp.config('effect_tsgo', {
  name = 'effect_tsgo',
  cmd = function(dispatchers, config)
    local root = (config or {}).root_dir
    local exe = find_effect_tsgo_exe(root)
    if not exe then
      -- Raise an error instead of returning an empty rpc: a broken client
      -- with `rpc = {}` stays registered in `vim.lsp.client._all` and crashes
      -- every later `reuse_client()` check with "attempt to call field
      -- 'is_closing' (a nil value)".
      error('effect_tsgo: could not resolve binary (root: ' .. (root or 'nil') .. ')')
    end
    return vim.lsp.rpc.start({ exe, '--lsp', '--stdio' }, dispatchers)
  end,
  filetypes = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { 'tsconfig.json', 'jsconfig.json', 'package.json', 'bun.lock', 'pnpm-lock.yaml', 'yarn.lock', 'package-lock.json' })
    if not find_effect_tsgo_exe(root) then
      -- Do not start (and do not call on_dir) when the binary is not present,
      -- so a broken client is never created in the first place.
      vim.notify_once('effect_tsgo: @effect/tsgo binary not found in ' .. (root or 'cwd') .. '; skipping effect_tsgo', vim.log.levels.WARN)
      return
    end
    on_dir(root or vim.fn.getcwd())
  end,
  settings = {
    typescript = {
      -- Verbose: mirrors Go's `err: error` for TS - shows all inferred types
      -- Toggle off with <leader>th (same as Go)
      inlayHints = {
        parameterNames = { enabled = 'all', suppressWhenArgumentMatchesName = false },
        parameterTypes = { enabled = true },
        variableTypes = { enabled = true, suppressWhenTypeMatchesName = false },
        propertyDeclarationTypes = { enabled = true },
        functionLikeReturnTypes = { enabled = true },
        enumMemberValues = { enabled = true },
      },
    },
    files = {
      watcherExclude = {
        ['**/.git/**'] = true,
        ['**/node_modules/**'] = true,
        ['**/dist/**'] = true,
      },
    },
  },
  capabilities = {
    workspace = {
      -- The Effect TypeScript-Go build registers invalid "bundled:///libs/**/*"
      -- file watcher globs that Neovim cannot parse. Disable dynamic file
      -- watching registration to avoid the glob errors.
      didChangeWatchedFiles = { dynamicRegistration = false },
    },
  },
  handlers = {
    -- Filter out invalid file watcher globs (e.g. "bundled:///libs/**/*")
    -- that this TypeScript-Go build registers, to avoid glob errors.
    ['client/registerCapability'] = function(err, params, ctx)
      if params and params.registrations then
        for _, reg in ipairs(params.registrations) do
          if reg.method == 'workspace/didChangeWatchedFiles' and reg.registerOptions then
            local watchers = reg.registerOptions.watchers
            if watchers then
              local filtered = {}
              for _, w in ipairs(watchers) do
                local pat = type(w.globPattern) == 'string' and w.globPattern or (w.globPattern and w.globPattern.pattern)
                if not (pat and pat:match '^bundled://') then table.insert(filtered, w) end
              end
              reg.registerOptions.watchers = filtered
            end
          end
        end
      end
      return vim.lsp.handlers['client/registerCapability'](err, params, ctx)
    end,
  },
})

vim.lsp.enable 'effect_tsgo'

-- ts_ls must never start in Effect projects: those are served only by
-- effect_tsgo. Refuse to start (do not call on_dir) when the @effect/tsgo
-- binary is present in the project root, so ts_ls is never created at all.
local ts_ls_cfg = vim.lsp.config['ts_ls']
local ts_ls_orig_root_dir = ts_ls_cfg and ts_ls_cfg.root_dir
vim.lsp.config('ts_ls', {
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { 'tsconfig.json', 'jsconfig.json', 'package.json', 'bun.lock', 'pnpm-lock.yaml', 'yarn.lock', 'package-lock.json' })
    if root and find_effect_tsgo_exe(root) then
      vim.notify_once('ts_ls: @effect/tsgo detected in ' .. root .. '; using effect_tsgo', vim.log.levels.WARN)
      return
    end
    if ts_ls_orig_root_dir then return ts_ls_orig_root_dir(bufnr, on_dir) end
    on_dir(root or vim.fn.getcwd())
  end,
})

-- Safety net: single gate decides before either server starts (root_dir above),
-- so double-attach should not happen. This only covers races where ts_ls
-- attached first; defer the stop so effect_tsgo finishes initializing.
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('effect-tsgo-override', { clear = true }),
  callback = function(args)
    local buf = args.buf
    local has_effect = false
    local ts_clients = {}
    for _, c in pairs(vim.lsp.get_clients { bufnr = buf }) do
      if c.name == 'effect_tsgo' then has_effect = true end
      if c.name == 'ts_ls' then table.insert(ts_clients, c) end
    end
    if has_effect and #ts_clients > 0 then
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buf) then return end
        for _, c in ipairs(ts_clients) do
          pcall(function() c:stop() end)
        end
      end)
    end
  end,
})

-- Helper commands
vim.api.nvim_create_user_command('EffectTsgoInfo', function()
  local clients = vim.lsp.get_clients { name = 'effect_tsgo' }
  if #clients == 0 then
    vim.notify('effect_tsgo: not running', vim.log.levels.WARN)
    return
  end
  for _, client in ipairs(clients) do
    local pid = client.rpc and client.rpc.pid or 'unknown'
    vim.notify(string.format('effect_tsgo: pid=%s, root=%s', pid, client.config.root_dir or 'unknown'), vim.log.levels.INFO)
  end
end, { desc = 'Show effect_tsgo LSP info' })

vim.api.nvim_create_user_command('EffectTsgoRestart', function()
  for _, client in pairs(vim.lsp.get_clients { name = 'effect_tsgo' }) do
    client:stop()
  end
  vim.defer_fn(function() vim.cmd 'edit' end, 100)
end, { desc = 'Restart effect_tsgo LSP' })

-- TS/JS helpers mirroring the Go workflow: organize imports + npm test.
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('ts-keymaps', { clear = true }),
  pattern = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
  callback = function(event)
    local buf = event.buf
    vim.keymap.set(
      'n',
      '<leader>co',
      function() vim.lsp.buf.code_action { context = { only = { 'source.organizeImports' } }, apply = true } end,
      { buffer = buf, desc = '[C]ode [O]rganize imports' }
    )
    vim.keymap.set('n', '<leader>cT', function() vim.cmd 'split | terminal npm test -- --watchAll=false' end, { buffer = buf, desc = '[C]ode [T]est (npm)' })
  end,
})
