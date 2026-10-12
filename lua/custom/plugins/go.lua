-- go.lua
-- Go-specific helpers: auto-organize imports, test runner, and lint registration

-- NOTE: golangci-lint for Go files is registered centrally in
-- kickstart.plugins.lint (`lint.linters_by_ft.go`), so there is no
-- duplicate registration here.

-- Import organization is handled by conform's goimports+gofumpt on save.
-- The old gopls `source.organizeImports` BufWritePre (sync, up to 800ms per
-- save) was redundant with that and blocked the UI, so it was removed.

-- Inlay hints for Go are OFF by default (opt-in via <leader>th).
-- gopls hint settings stay enabled server-side in init.lua so that
-- toggling displays `ctx: context.Context, err: error` in grey.

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
      local path = vim.fs.joinpath(dir, target)
      if vim.fn.filereadable(path) == 1 then
        vim.cmd('edit ' .. path)
      else
        vim.notify('File not found: ' .. target, vim.log.levels.WARN)
      end
    end, { buffer = buf, desc = '[G]o [A]lternate (test/impl)' })
  end,
})
