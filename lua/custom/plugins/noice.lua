vim.pack.add { 'https://github.com/folke/noice.nvim' }
vim.pack.add { 'https://github.com/MunifTanjim/nui.nvim' }
vim.pack.add { 'https://github.com/rcarriga/nvim-notify' }

-- Defer 9.8ms until after --- NVIM STARTED --- (VimEnter + schedule)
vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('lazy-noice', { clear = true }),
  callback = function()
    vim.schedule(
      function()
        require('noice').setup {
          lsp = {
            override = {
              ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
              ['vim.lsp.util.stylize_markdown'] = true,
            },
          },
          presets = {
            bottom_search = true,
            command_palette = true,
            long_message_to_split = true,
            lsp_doc_border = true,
          },
        }
      end
    )
  end,
})
