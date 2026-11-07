-- harpoon.lua
-- Harpoon 2: pin the files you keep returning to and jump straight to them.
-- https://github.com/ThePrimeagen/harpoon (harpoon2 branch)
-- Dependency: nvim-lua/plenary.nvim (installed in init.lua SECTION 4).
vim.pack.add { { src = 'https://github.com/ThePrimeagen/harpoon', version = 'harpoon2' } }

-- Keep one list per git repository, even when Neovim starts in a subdirectory.
local function project_root() return vim.fs.root(vim.uv.cwd(), '.git') or vim.uv.cwd() end

-- Lazy setup: `harpoon:setup()` registers autocmds and only needs to run before
-- the first Harpoon action. Same first-use pattern as flash.lua.
local harpoon
local function get_harpoon()
  if harpoon then return harpoon end
  harpoon = require 'harpoon'
  harpoon:setup {
    -- Save menu edits (for example `dd`) when the menu is closed.
    settings = { save_on_toggle = true, key = project_root },
    -- Store item paths relative to the same project root.
    default = { get_root_dir = project_root },
  }

  -- Highlight the file currently being edited in the quick menu.
  harpoon:extend(require('harpoon.extensions').builtins.highlight_current_file())

  -- Open a menu entry in a split/tab without closing the menu first.
  harpoon:extend {
    UI_CREATE = function(cx)
      vim.keymap.set(
        'n',
        '<C-v>',
        function() harpoon.ui:select_menu_item { vsplit = true } end,
        { buffer = cx.bufnr, desc = 'Harpoon: open in vertical split' }
      )
      vim.keymap.set(
        'n',
        '<C-x>',
        function() harpoon.ui:select_menu_item { split = true } end,
        { buffer = cx.bufnr, desc = 'Harpoon: open in horizontal split' }
      )
      vim.keymap.set('n', '<C-t>', function() harpoon.ui:select_menu_item { tabedit = true } end, { buffer = cx.bufnr, desc = 'Harpoon: open in new tab' })
    end,
  }

  return harpoon
end

-- <leader>h = [H]arpoon (shared with gitsigns' Git [H]unk mappings)
vim.keymap.set('n', '<leader>ha', function() get_harpoon():list():add() end, { desc = 'Harpoon: [A]dd current file' })
vim.keymap.set('n', '<leader>hh', function()
  local h = get_harpoon()
  h.ui:toggle_quick_menu(h:list())
end, { desc = 'Harpoon: open [H]arpoon quick menu' })

for i = 1, 4 do
  vim.keymap.set('n', '<leader>' .. i, function() get_harpoon():list():select(i) end, { desc = 'Harpoon: go to file ' .. i })
end

vim.keymap.set('n', '<leader>hn', function() get_harpoon():list():next { ui_nav_wrap = true } end, { desc = 'Harpoon: [N]ext file' })
-- NOTE: <leader>hp is gitsigns' preview_hunk, so Harpoon previous uses <leader>hP.
vim.keymap.set('n', '<leader>hP', function() get_harpoon():list():prev { ui_nav_wrap = true } end, { desc = 'Harpoon: [P]revious file' })

-- `list:remove()` leaves a hole in the list, so rebuild it compactly instead.
local function remove_current_file()
  local h = get_harpoon()
  local list = h:list()
  local current = list.config.create_list_item(list.config)
  local kept = {}
  for i = 1, list:length() do
    local item = list.items[i]
    if item and not list.config.equals(item, current) then kept[#kept + 1] = item end
  end
  list:clear()
  for _, item in ipairs(kept) do
    list:add(item)
  end
  h:sync()
end

vim.keymap.set('n', '<leader>hx', remove_current_file, { desc = 'Harpoon: remove current file' })

-- Fuzzy-find the saved files with Telescope, including its file preview.
local function harpoon_telescope()
  local list = get_harpoon():list()
  local files = {}
  for i = 1, list:length() do
    local item = list.items[i]
    if item then files[#files + 1] = item.value end
  end
  if #files == 0 then
    vim.notify('Harpoon list is empty', vim.log.levels.WARN)
    return
  end

  local conf = require('telescope.config').values
  require('telescope.pickers')
    .new({}, {
      prompt_title = 'Harpoon',
      finder = require('telescope.finders').new_table { results = files },
      previewer = conf.file_previewer {},
      sorter = conf.generic_sorter {},
    })
    :find()
end

vim.keymap.set('n', '<leader>hT', harpoon_telescope, { desc = 'Harpoon: open list in [T]elescope' })
