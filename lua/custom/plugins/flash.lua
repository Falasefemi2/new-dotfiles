vim.pack.add { 'https://github.com/folke/flash.nvim' }

-- Lazy setup: only when `s` is first pressed (flash.setup is ~3ms + require).
local flash_setup = false
local function ensure_flash()
  if flash_setup then return end
  flash_setup = true
  require('flash').setup()
end

vim.keymap.set({ 'n', 'x', 'o' }, 's', function()
  ensure_flash()
  require('flash').jump()
end, { desc = 'Flash jump' })
