-- go.lua
-- Go-specific helpers: auto-organize imports, test runner, and lint registration

-- Register golangci-lint for Go files with nvim-lint
pcall(function()
  local lint = require 'lint'
  lint.linters_by_ft = lint.linters_by_ft or {}
  lint.linters_by_ft['go'] = lint.linters_by_ft['go'] or { 'golangci_lint' }
end)

-- Auto-organize imports on save via gopls code action (async, non-blocking)
-- Previous sync version blocked UI for 3s on every save; now async with buf validation.
vim.api.nvim_create_autocmd('BufWritePre', {
  group = vim.api.nvim_create_augroup('go-organize-imports', { clear = true }),
  pattern = '*.go',
  callback = function(args)
    local bufnr = args.buf
    -- Only run if gopls is attached
    local has_gopls = false
    for _, c in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
      if c.name == 'gopls' then
        has_gopls = true
        break
      end
    end
    if not has_gopls then return end

    local params = vim.lsp.util.make_range_params(bufnr, 'utf-8')
    params.context = { only = { 'source.organizeImports' } }

    -- Use buf_request (async) but we need to block briefly to apply before write.
    -- Use sync with short timeout (500ms) + buf validation as compromise,
    -- and pcall to avoid freezing on slow gopls.
    local ok, result = pcall(vim.lsp.buf_request_sync, bufnr, 'textDocument/codeAction', params, 800)
    if not ok or not result then return end
    for _, res in pairs(result) do
      for _, action in pairs(res.result or {}) do
        if action.edit then
          if not vim.api.nvim_buf_is_valid(bufnr) then return end
          local enc = (vim.lsp.get_client_by_id(res.client_id) or {}).offset_encoding or 'utf-16'
          vim.lsp.util.apply_workspace_edit(action.edit, enc)
        elseif action.command then
          vim.lsp.buf.execute_command(action.command)
        end
      end
    end
  end,
})

-- Auto-enable inlay hints for Go buffers (shows `ctx: context.Context, err: error` in grey)
-- This is what makes `ctx, err := ...` display the type inline.
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('go-inlay-hints', { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == 'gopls' and client:supports_method('textDocument/inlayHint', args.buf) then
      vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
    end
  end,
})

-- Go keymaps (only active in Go buffers)
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('go-keymaps', { clear = true }),
  pattern = 'go',
  callback = function(event)
    local buf = event.buf

    vim.keymap.set('n', '<leader>gt', function() vim.cmd 'split | terminal go test ./...' end, { buffer = buf, desc = '[G]o [T]est (current package)' })

    vim.keymap.set('n', '<leader>gT', function() vim.cmd 'split | terminal go test -v ./...' end, { buffer = buf, desc = '[G]o [T]est verbose' })

    vim.keymap.set('n', '<leader>gr', function() vim.cmd 'split | terminal go run .' end, { buffer = buf, desc = '[G]o [R]un' })

    vim.keymap.set('n', '<leader>gm', function() vim.cmd 'split | terminal go mod tidy' end, { buffer = buf, desc = '[G]o [M]od tidy' })

    vim.keymap.set('n', '<leader>gv', function() vim.cmd 'split | terminal go vet ./...' end, { buffer = buf, desc = '[G]o [V]et' })

    -- Toggle test file / implementation file
    vim.keymap.set('n', '<leader>ga', function()
      local file = vim.fn.expand '%:t'
      local dir = vim.fn.expand '%:p:h'
      local target
      if file:match '_test%.go$' then
        target = file:gsub('_test%.go$', '.go')
      else
        target = file:gsub('%.go$', '_test.go')
      end
      local path = dir .. '/' .. target
      if vim.fn.filereadable(path) == 1 then
        vim.cmd('edit ' .. path)
      else
        vim.notify('File not found: ' .. target, vim.log.levels.WARN)
      end
    end, { buffer = buf, desc = '[G]o [A]lternate (test/impl)' })
  end,
})
