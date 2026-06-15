vim.pack.add({ "https://github.com/akinsho/toggleterm.nvim" })

require("toggleterm").setup({
  open_mapping = [[<C-\>]],
})

local Terminal = require("toggleterm.terminal").Terminal

local float_term = Terminal:new({
  direction = "float",
})

local vertical_term = Terminal:new({
  direction = "vertical",
  size = vim.o.columns * 0.3,
})

local horizontal_term = Terminal:new({
  direction = "horizontal",
  size = 15,
})

vim.keymap.set("n", "<leader>tf", function()
  float_term:toggle()
end, { desc = "Float Terminal" })

vim.keymap.set("n", "<leader>tv", function()
  vertical_term:toggle()
end, { desc = "Vertical Terminal" })

vim.keymap.set("n", "<leader>th", function()
  horizontal_term:toggle()
end, { desc = "Horizontal Terminal" })
