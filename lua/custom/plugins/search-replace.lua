-- plenary comes from SECTION 4 (telescope); not duplicated here.
vim.pack.add {
  'https://github.com/nvim-pack/nvim-spectre',
}

-- Lazy 26ms spectre.ui + 9ms spectre - only on first <leader>r use
local spectre_setup = false
local function ensure_spectre()
  if spectre_setup then return end
  spectre_setup = true
  require('spectre').setup {
    color_devicons = vim.g.have_nerd_font,
    live_update = true,
    is_insert_mode = true,
    use_trouble_qf = false,
  }
end

vim.keymap.set('n', '<leader>rp', function()
  ensure_spectre()
  require('spectre').toggle()
end, { desc = '[R]eplace in [P]roject (Spectre)' })
vim.keymap.set('n', '<leader>rP', function()
  ensure_spectre()
  require('spectre').open_visual { select_word = true }
end, { desc = '[R]eplace [P]roject word under cursor' })
vim.keymap.set('n', '<leader>rf', function()
  ensure_spectre()
  require('spectre').open_file_search { select_word = true }
end, { desc = '[R]eplace in current [F]ile (Spectre)' })

local function get_selected_text()
  local old = vim.fn.getreg 'v'
  vim.fn.setreg('v', '')
  vim.cmd.normal { 'gv"vy', bang = true }
  local text = vim.fn.getreg 'v'
  vim.fn.setreg('v', old)
  return text
end

---Ask for the replacement, then run the substitute. Prompting (instead of
---pre-filling `:s/.../g`) means an accidental <CR> can never replace every
---match with the literal "g" or delete them via an empty replacement.
---@param word string
---@param range string '%' for the file, or '<line>,<line>' for a selection
local function prompt_replace(word, range)
  vim.ui.input({ prompt = ('Replace "%s" with: '):format(word) }, function(input)
    if not input or input == '' then return end
    local pattern = '\\V\\<' .. vim.fn.escape(word, '/\\') .. '\\>'
    local replacement = vim.fn.escape(input, '\\/&~|')
    local ok, err = pcall(vim.cmd, range .. 's/' .. pattern .. '/' .. replacement .. '/g')
    if not ok then vim.notify('Replace failed: ' .. err, vim.log.levels.ERROR) end
  end)
end

local function replace_word()
  local word = vim.fn.expand '<cword>'
  if word == '' then
    vim.notify('No word under cursor', vim.log.levels.WARN)
    return
  end
  prompt_replace(word, '%')
end

vim.keymap.set('n', '<leader>rr', replace_word, { desc = '[R]eplace word under cursor (whole file)' })

vim.keymap.set('x', '<leader>rr', function()
  local word = get_selected_text()
  word = word:gsub('^%s+', ''):gsub('%s+$', '')
  if word == '' then return end
  local first, last = vim.fn.line("'<"), vim.fn.line "'>"
  prompt_replace(word, first .. ',' .. last)
end, { desc = '[R]eplace selection text' })
