-- lua/custom/floatterm.lua
-- Multi-instance floating terminals. No plugin dependencies.
--
-- Design:
--   * Every terminal owns exactly one unlisted buffer and one job.
--   * Windows are disposable: hiding closes the window only (bufhidden=hide),
--     so scrollback and the shell survive. Only close() kills a job/buffer.
--   * Geometry is stored in the registry, not in the window, so hide/show and
--     VimResized never reset a user's position/size.

local M = {}

local api = vim.api

local defaults = {
  -- Ratios (0 < n <= 1) of columns/lines, or absolute cell counts (> 1).
  width = 0.62,
  height = 0.55,
  border = 'rounded',
  -- nil -> &shell. String -> split into argv. Table -> used as argv.
  shell = nil,
  cwd = nil,
  env = nil,
  -- Optional border title: function(id) -> string. Default: ' term <id> '.
  title = nil,
  winblend = 0,
  start_insert = true,
  move_step = 2,
  resize_step = 2,
  min_width = 20,
  min_height = 5,
  mouse = true,
  keymaps = {
    new = '<leader>tn',
    toggle = '<leader>tt',
    toggle_alt = '<C-\\>',
    toggle_all = '<leader>ta',
    focus_next = '<leader>t]',
    focus_prev = '<leader>t[',
    close = '<leader>tq',
    pick = '<leader>ts',
    numbered = '<leader>t',
    move_left = '<A-h>',
    move_down = '<A-j>',
    move_up = '<A-k>',
    move_right = '<A-l>',
    resize_left = '<A-H>',
    resize_down = '<A-J>',
    resize_up = '<A-K>',
    resize_right = '<A-L>',
  },
}

local state = {
  opts = vim.deepcopy(defaults),
  terms = {},
  next_id = 1,
  active = nil,
  prev_win = nil,
  zindex = 50,
  drag = nil,
}

local HL = {
  normal = 'FloatTermNormal',
  border_active = 'FloatTermBorderActive',
  border_inactive = 'FloatTermBorderInactive',
  title_active = 'FloatTermTitleActive',
  title_inactive = 'FloatTermTitleInactive',
}

-- ---------------------------------------------------------------------------
-- Small helpers
-- ---------------------------------------------------------------------------

local function is_valid_win(win) return win ~= nil and api.nvim_win_is_valid(win) end
local function is_valid_buf(buf) return buf ~= nil and api.nvim_buf_is_valid(buf) end
local function current_win() return api.nvim_get_current_win() end
local function border_pad() return state.opts.border == 'none' and 0 or 1 end

local function term_by_win(win)
  for id, t in pairs(state.terms) do
    if t.win == win then return id, t end
  end
end

local function term_by_buf(buf)
  for id, t in pairs(state.terms) do
    if t.buf == buf then return id, t end
  end
end

local function sorted_ids(visible_only)
  local ids = {}
  for id, t in pairs(state.terms) do
    if not visible_only or is_valid_win(t.win) then ids[#ids + 1] = id end
  end
  table.sort(ids)
  return ids
end

local function first_id()
  local ids = sorted_ids()
  return ids[1]
end

local function title_for(id)
  local title = state.opts.title
  if type(title) == 'function' then return title(id) end
  return (' term %d '):format(id)
end

-- ---------------------------------------------------------------------------
-- Highlighting (per-window winhighlight only; never changes global groups
-- after setup, so colorscheme switches keep working)
-- ---------------------------------------------------------------------------

local function define_highlights()
  local function set(name, spec)
    if vim.fn.hlexists(name) == 0 then api.nvim_set_hl(0, name, spec) end
  end
  set(HL.normal, { link = 'NormalFloat' })
  set(HL.border_active, { link = 'DiagnosticInfo' })
  set(HL.border_inactive, { link = 'Comment' })
  set(HL.title_active, { link = 'Title' })
  set(HL.title_inactive, { link = 'Comment' })
end

local function winhighlight(active)
  return table.concat({
    'Normal:' .. HL.normal,
    'FloatBorder:' .. (active and HL.border_active or HL.border_inactive),
    'FloatTitle:' .. (active and HL.title_active or HL.title_inactive),
  }, ',')
end

local function refresh_highlights()
  local cur = current_win()
  for _, t in pairs(state.terms) do
    if is_valid_win(t.win) then pcall(api.nvim_set_option_value, 'winhighlight', winhighlight(t.win == cur), { win = t.win }) end
  end
end

-- ---------------------------------------------------------------------------
-- Geometry
-- ---------------------------------------------------------------------------

local function resolve_dim(value, total, fallback)
  if type(value) == 'function' then value = value(total) end
  if type(value) ~= 'number' then value = fallback end
  if value > 0 and value <= 1 then return math.max(1, math.floor(total * value)) end
  return math.max(1, math.floor(value))
end

local function clamp_geometry(g)
  local cols, lines = vim.o.columns, vim.o.lines
  local pad = border_pad()
  local max_w = math.max(1, cols - 2 * pad)
  local max_h = math.max(1, lines - 2 * pad)
  local min_w = math.min(state.opts.min_width, max_w)
  local min_h = math.min(state.opts.min_height, max_h)

  g.width = math.min(math.max(math.floor(g.width or min_w), min_w), max_w)
  g.height = math.min(math.max(math.floor(g.height or min_h), min_h), max_h)
  -- row/col are the text area. With a border, leave one cell for it.
  g.row = math.min(math.max(math.floor(g.row or pad), pad), lines - g.height - pad)
  g.col = math.min(math.max(math.floor(g.col or pad), pad), cols - g.width - pad)
  return g
end

local function default_geometry(id)
  local cols, lines = vim.o.columns, vim.o.lines
  local pad = border_pad()
  local width = math.min(resolve_dim(state.opts.width, cols, 0.62), cols - 2 * pad)
  local height = math.min(resolve_dim(state.opts.height, lines, 0.55), lines - 2 * pad)
  -- Cascade so simultaneously visible terminals are not perfectly stacked.
  local offset = ((id - 1) % 5) * 2
  return clamp_geometry {
    width = width,
    height = height,
    row = math.floor((lines - height) / 2) + offset,
    col = math.floor((cols - width) / 2) + offset,
  }
end

local function save_geometry(t)
  if not is_valid_win(t.win) then return end
  local cfg = api.nvim_win_get_config(t.win)
  if cfg.relative == 'editor' then t.geometry = { width = cfg.width, height = cfg.height, row = cfg.row, col = cfg.col } end
end

local function set_geometry(win, g)
  local cfg = { relative = 'editor', row = g.row, col = g.col, width = g.width, height = g.height }
  if state.opts.border ~= 'none' then
    local id = term_by_win(win)
    cfg.border = state.opts.border
    if id then cfg.title = title_for(id) end
    cfg.title_pos = 'center'
  end
  api.nvim_win_set_config(win, cfg)
end

-- ---------------------------------------------------------------------------
-- Focus and stacking
-- ---------------------------------------------------------------------------

local function restore_focus()
  if is_valid_win(state.prev_win) and not term_by_win(state.prev_win) then
    api.nvim_set_current_win(state.prev_win)
    return
  end
  for _, win in ipairs(api.nvim_list_wins()) do
    local ok, cfg = pcall(api.nvim_win_get_config, win)
    if ok and cfg.relative == '' then
      api.nvim_set_current_win(win)
      return
    end
  end
end

local function raise(t)
  state.zindex = state.zindex + 1
  if state.zindex > 400 then
    state.zindex = 50
    for _, other in pairs(state.terms) do
      if is_valid_win(other.win) then
        state.zindex = state.zindex + 1
        other.zindex = state.zindex
        pcall(api.nvim_win_set_config, other.win, { zindex = other.zindex })
      end
    end
  end
  t.zindex = state.zindex
  if is_valid_win(t.win) then pcall(api.nvim_win_set_config, t.win, { zindex = t.zindex }) end
end

local function focus_term(id, insert)
  local t = state.terms[id]
  if not t or not is_valid_win(t.win) then return end
  api.nvim_set_current_win(t.win)
  raise(t)
  state.active = id
  refresh_highlights()
  if insert and state.opts.start_insert and vim.bo[t.buf].buftype == 'terminal' then vim.cmd.startinsert() end
end

-- ---------------------------------------------------------------------------
-- Window lifecycle
-- ---------------------------------------------------------------------------

local function win_config(t)
  local g = t.geometry
  local cfg = {
    relative = 'editor',
    row = g.row,
    col = g.col,
    width = g.width,
    height = g.height,
    style = 'minimal',
    zindex = t.zindex,
    focusable = true,
  }
  if state.opts.border ~= 'none' then
    cfg.border = state.opts.border
    cfg.title = title_for(t.id)
    cfg.title_pos = 'center'
  end
  return cfg
end

local function open_win(t, focus)
  local win = api.nvim_open_win(t.buf, false, win_config(t))
  t.win = win
  t.visible = true
  api.nvim_set_option_value('winhighlight', winhighlight(false), { win = win })
  api.nvim_set_option_value('winblend', state.opts.winblend, { win = win })
  -- Floating terminals never show the breadcrumb winbar.
  api.nvim_set_option_value('winbar', '', { win = win })
  if focus then
    api.nvim_set_current_win(win)
    raise(t)
    refresh_highlights()
  end
  return win
end

local function hide(id)
  local t = state.terms[id]
  if not t or not is_valid_win(t.win) then return end
  save_geometry(t)
  local was_current = current_win() == t.win
  local win = t.win
  pcall(api.nvim_win_close, win, true)
  if t.win == win then t.win = nil end
  t.visible = false
  if was_current then restore_focus() end
  refresh_highlights()
end

-- ---------------------------------------------------------------------------
-- Job lifecycle
-- ---------------------------------------------------------------------------

local function shell_argv()
  local shell = state.opts.shell
  if type(shell) == 'function' then shell = shell() end
  if type(shell) == 'table' then return shell end
  if type(shell) == 'string' and shell ~= '' then return vim.split(shell, '%s+', { trimempty = true }) end
  return vim.split(vim.o.shell, '%s+', { trimempty = true })
end

local function start_job(t, cmd)
  local job_cmd = cmd
  if job_cmd == nil or job_cmd == '' then job_cmd = shell_argv() end

  -- Empty Lua tables are encoded as lists; termopen() requires a dictionary.
  local opts = vim.empty_dict()
  if state.opts.cwd then opts.cwd = state.opts.cwd end
  if state.opts.env then opts.env = state.opts.env end

  local ok, job = pcall(vim.fn.termopen, job_cmd, opts)
  if not ok then return nil, tostring(job) end
  if type(job) ~= 'number' or job <= 0 then return nil, ('termopen returned %s'):format(tostring(job)) end
  return job
end

local function cleanup(id, buf)
  local t = state.terms[id]
  if not t then return end
  local was_current = is_valid_win(t.win) and current_win() == t.win
  if is_valid_win(t.win) then pcall(api.nvim_win_close, t.win, true) end
  state.terms[id] = nil
  if is_valid_buf(buf or t.buf) then pcall(api.nvim_buf_delete, buf or t.buf, { force = true }) end
  if state.active == id then state.active = first_id() end
  if was_current then restore_focus() end
  refresh_highlights()
end

-- ---------------------------------------------------------------------------
-- Mouse: click raises/focuses, border/title drag moves, bottom-right resizes
-- ---------------------------------------------------------------------------

local function feed_default(key)
  local keys = api.nvim_replace_termcodes(key, true, false, true)
  api.nvim_feedkeys(keys, 'n', false)
end

local function mouse_pos()
  local m = vim.fn.getmousepos()
  if m.screenrow <= 0 or m.screencol <= 0 then return nil end
  return { row = m.screenrow - 1, col = m.screencol - 1 }
end

local function float_at(row, col)
  local pad = border_pad()
  local best
  for id, t in pairs(state.terms) do
    if is_valid_win(t.win) then
      -- For floats, nvim_win_get_position() is the border's top-left corner,
      -- not the text area. The text starts one cell inside when a border exists.
      local pos = api.nvim_win_get_position(t.win)
      local cfg = api.nvim_win_get_config(t.win)
      local top, left = pos[1], pos[2]
      local text_top, text_left = top + pad, left + pad
      local w, h = cfg.width, cfg.height
      local outer_bottom, outer_right = text_top + h - 1 + pad, text_left + w - 1 + pad

      if row >= top and row <= outer_bottom and col >= left and col <= outer_right then
        local inside = row >= text_top and row < text_top + h and col >= text_left and col < text_left + w
        local corner = (row >= text_top + h - 1 and col >= text_left + w - 1) and not inside
        if not best or (t.zindex or 0) > (best.t.zindex or 0) then best = { id = id, t = t, inside = inside, corner = corner } end
      end
    end
  end
  if best then return best.id, best.t, best.inside, best.corner end
end

local function mouse_down()
  local m = mouse_pos()
  if not m then return false end
  local id, t, inside, corner = float_at(m.row, m.col)
  if not id then return false end

  local mode = api.nvim_get_mode().mode
  api.nvim_set_current_win(t.win)
  raise(t)
  state.active = id
  refresh_highlights()

  if inside then
    -- In normal mode a click on a float means "start typing in it". In terminal
    -- mode, let the click through so full-screen TUI mouse support keeps working.
    if mode == 'n' and state.opts.start_insert then vim.cmd.startinsert() end
    return mode ~= 't'
  end

  save_geometry(t)
  state.drag = {
    id = id,
    kind = corner and 'resize' or 'move',
    start_row = m.row,
    start_col = m.col,
    geometry = vim.deepcopy(t.geometry),
    was_terminal = mode == 't',
  }
  return true
end

local function mouse_drag()
  local drag = state.drag
  if not drag then return false end
  local t = state.terms[drag.id]
  if not t or not is_valid_win(t.win) then
    state.drag = nil
    return true
  end

  local m = mouse_pos()
  if not m then return true end
  local drow, dcol = m.row - drag.start_row, m.col - drag.start_col
  local g = vim.deepcopy(drag.geometry)
  if drag.kind == 'move' then
    g.row, g.col = g.row + drow, g.col + dcol
  else
    g.width, g.height = g.width + dcol, g.height + drow
  end
  g = clamp_geometry(g)
  t.geometry = g
  set_geometry(t.win, g)
  return true
end

local function mouse_release()
  local drag = state.drag
  if not drag then return false end
  state.drag = nil
  if drag.was_terminal then
    local t = state.terms[drag.id]
    if t and is_valid_win(t.win) and current_win() == t.win and vim.bo[t.buf].buftype == 'terminal' then vim.cmd.startinsert() end
  end
  return true
end

-- ---------------------------------------------------------------------------
-- Keyboard move/resize
-- ---------------------------------------------------------------------------

local function current_float()
  local id, t = term_by_win(current_win())
  if id then return id, t end
end

local function move(drow, dcol)
  local _, t = current_float()
  if not t or not is_valid_win(t.win) then return end
  local g = vim.deepcopy(t.geometry)
  g.row, g.col = g.row + drow, g.col + dcol
  g = clamp_geometry(g)
  t.geometry = g
  set_geometry(t.win, g)
end

local function resize(dw, dh)
  local _, t = current_float()
  if not t or not is_valid_win(t.win) then return end
  local g = vim.deepcopy(t.geometry)
  g.width, g.height = g.width + dw, g.height + dh
  g = clamp_geometry(g)
  t.geometry = g
  set_geometry(t.win, g)
end

-- ---------------------------------------------------------------------------
-- Autocmds
-- ---------------------------------------------------------------------------

local function on_win_closed(win)
  local id, t = term_by_win(win)
  if not id then return end
  if t.win == win then t.win = nil end
  t.visible = false
  if state.active == id then state.active = first_id() end
  refresh_highlights()
end

local function on_term_close(buf)
  local id, t = term_by_buf(buf)
  if not id or t.closing then return end
  vim.schedule(function()
    local cur = state.terms[id]
    if cur and not cur.closing then cleanup(id, buf) end
  end)
end

local function on_resize()
  for id, t in pairs(state.terms) do
    if is_valid_win(t.win) then
      save_geometry(t)
      t.geometry = clamp_geometry(t.geometry)
      set_geometry(t.win, t.geometry)
    else
      t.geometry = clamp_geometry(t.geometry or default_geometry(id))
    end
  end
  refresh_highlights()
end

local function on_quit_pre()
  local cur = current_win()
  if term_by_win(cur) then
    -- Quitting from a float: only force-close when it is the last window left,
    -- otherwise let :q hide it normally.
    local others = 0
    for _, win in ipairs(api.nvim_list_wins()) do
      if win ~= cur and not term_by_win(win) then others = others + 1 end
    end
    if others == 0 then
      local id = term_by_win(cur)
      if id then M.close(id) end
    end
    return
  end

  -- Quitting the last normal window: close float windows first so they do not
  -- keep Neovim alive or trigger the "job still running" prompt. Jobs are
  -- killed on VimLeavePre; hidden terminal buffers do not block :q.
  local other_normal = 0
  for _, win in ipairs(api.nvim_list_wins()) do
    if win ~= cur and not term_by_win(win) then other_normal = other_normal + 1 end
  end
  if other_normal == 0 then
    for id in pairs(state.terms) do
      hide(id)
    end
  end
end

local function on_vim_leave()
  for _, t in pairs(state.terms) do
    if t.job then pcall(vim.fn.jobstop, t.job) end
    if is_valid_buf(t.buf) then pcall(api.nvim_buf_delete, t.buf, { force = true }) end
  end
  state.terms = {}
end

local function setup_autocmds()
  local group = api.nvim_create_augroup('FloatTerm', { clear = true })

  api.nvim_create_autocmd('WinClosed', {
    group = group,
    desc = 'FloatTerm: forget closed windows without killing jobs',
    callback = function(ev) on_win_closed(tonumber(ev.match)) end,
  })
  api.nvim_create_autocmd('WinLeave', {
    group = group,
    desc = 'FloatTerm: persist geometry before leaving a float',
    callback = function()
      local _, t = term_by_win(current_win())
      if t then save_geometry(t) end
    end,
  })
  api.nvim_create_autocmd('TermClose', {
    group = group,
    desc = 'FloatTerm: clean up instances whose shell exited',
    callback = function(ev) on_term_close(ev.buf) end,
  })
  api.nvim_create_autocmd('BufWipeout', {
    group = group,
    desc = 'FloatTerm: forget buffers wiped outside the module',
    callback = function(ev)
      local id, t = term_by_buf(ev.buf)
      if not id or t.closing then return end
      local was_current = is_valid_win(t.win) and current_win() == t.win
      if is_valid_win(t.win) then pcall(api.nvim_win_close, t.win, true) end
      state.terms[id] = nil
      if state.active == id then state.active = first_id() end
      if was_current then restore_focus() end
      refresh_highlights()
    end,
  })
  api.nvim_create_autocmd('VimResized', {
    group = group,
    desc = 'FloatTerm: clamp floats instead of resetting geometry',
    callback = on_resize,
  })
  api.nvim_create_autocmd('WinEnter', {
    group = group,
    desc = 'FloatTerm: refresh focused/unfocused borders',
    callback = refresh_highlights,
  })
  api.nvim_create_autocmd('QuitPre', {
    group = group,
    desc = 'FloatTerm: do not let floats block quitting',
    callback = on_quit_pre,
  })
  api.nvim_create_autocmd('VimLeavePre', {
    group = group,
    desc = 'FloatTerm: stop all terminal jobs on exit',
    callback = on_vim_leave,
  })
  api.nvim_create_autocmd('ColorScheme', {
    group = group,
    desc = 'FloatTerm: refresh border/title links after a theme change',
    callback = function()
      define_highlights()
      refresh_highlights()
    end,
  })
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

---Open a new floating terminal. Always creates a new instance.
---@param cmd? string|string[] Command to run; nil uses opts.shell.
---@return integer|nil id
function M.new(cmd)
  local id = state.next_id
  state.next_id = state.next_id + 1
  return M._create(id, cmd)
end

---@private
function M._create(id, cmd)
  id = math.floor(id)
  if state.terms[id] then
    id = state.next_id
    state.next_id = state.next_id + 1
  else
    state.next_id = math.max(state.next_id, id + 1)
  end

  -- Not a scratch buffer: termopen() requires an empty, normal buffer.
  local buf = api.nvim_create_buf(false, false)
  vim.bo[buf].buflisted = false
  vim.bo[buf].bufhidden = 'hide'
  vim.bo[buf].swapfile = false
  vim.b[buf].floatterm_id = id

  local t = {
    id = id,
    buf = buf,
    win = nil,
    job = nil,
    geometry = default_geometry(id),
    visible = false,
    zindex = state.zindex,
    cmd = cmd,
  }
  state.terms[id] = t

  local cur = current_win()
  if not term_by_win(cur) then state.prev_win = cur end

  local ok, err = pcall(open_win, t, true)
  if not ok then
    state.terms[id] = nil
    pcall(api.nvim_buf_delete, buf, { force = true })
    vim.notify('FloatTerm: could not open window: ' .. tostring(err), vim.log.levels.ERROR)
    return nil
  end

  local job, job_err = start_job(t, cmd)
  if not job then
    pcall(api.nvim_win_close, t.win, true)
    state.terms[id] = nil
    pcall(api.nvim_buf_delete, buf, { force = true })
    restore_focus()
    vim.notify('FloatTerm: could not start job: ' .. tostring(job_err), vim.log.levels.ERROR)
    return nil
  end

  t.job = job
  vim.bo[buf].buflisted = false
  vim.bo[buf].bufhidden = 'hide'
  state.active = id
  refresh_highlights()
  if state.opts.start_insert then vim.cmd.startinsert() end
  return id
end

---Show or hide a terminal. With no id, toggles the active/focused float.
---@param id? integer
function M.toggle(id)
  if id == nil then
    local cur = term_by_win(current_win())
    id = cur or state.active or first_id()
  end
  if not id then return M.new() end
  if id < 1 then return end

  local t = state.terms[id]
  if not t then return M._create(id, nil) end
  if is_valid_win(t.win) then
    hide(id)
  else
    M.show(id, true)
  end
end

---Show a terminal, restoring its saved geometry and scrollback.
---@param id integer
---@param focus? boolean
function M.show(id, focus)
  local t = state.terms[id]
  if not t then return end
  if not is_valid_buf(t.buf) then
    state.terms[id] = nil
    return
  end

  if is_valid_win(t.win) then
    if focus ~= false then focus_term(id, true) end
    return
  end

  if focus ~= false then
    local cur = current_win()
    if not term_by_win(cur) then state.prev_win = cur end
  end

  t.geometry = clamp_geometry(t.geometry or default_geometry(id))
  open_win(t, focus ~= false)
  state.active = id
  refresh_highlights()
  if focus ~= false and state.opts.start_insert and vim.bo[t.buf].buftype == 'terminal' then vim.cmd.startinsert() end
end

---Toggle every known terminal: hide all if any are visible, otherwise show all.
function M.toggle_all()
  local any_visible = false
  for _, t in pairs(state.terms) do
    if is_valid_win(t.win) then
      any_visible = true
      break
    end
  end

  if any_visible then
    for id in pairs(state.terms) do
      hide(id)
    end
    return
  end

  local ids = sorted_ids()
  if #ids == 0 then return M.new() end

  local target = state.active and state.terms[state.active] and state.active or ids[1]
  for _, id in ipairs(ids) do
    M.show(id, false)
  end
  if target then M.show(target, true) end
end

---Cycle focus through visible floats. step = 1 next, -1 previous.
---@param step? integer
function M.focus_next(step)
  step = step or 1
  local ids = sorted_ids(true)
  if #ids == 0 then
    local id = state.active or first_id()
    if id and state.terms[id] then return M.show(id, true) end
    return M.new()
  end

  local cur = term_by_win(current_win())
  local index
  for i, id in ipairs(ids) do
    if id == cur then
      index = i
      break
    end
  end
  if not index then index = step > 0 and 0 or 1 end
  local next_index = ((index - 1 + step) % #ids) + 1
  M.show(ids[next_index], true)
end

---Kill a terminal's job and delete its buffer. With no id, closes the focused
---float, else the active terminal.
---@param id? integer
function M.close(id)
  if id == nil then
    local cur = term_by_win(current_win())
    id = cur or state.active or first_id()
  end
  if not id or id < 1 then return end

  local t = state.terms[id]
  if not t then return end

  t.closing = true
  local was_current = is_valid_win(t.win) and current_win() == t.win
  if is_valid_win(t.win) then pcall(api.nvim_win_close, t.win, true) end
  t.win = nil
  t.visible = false
  if t.job then pcall(vim.fn.jobstop, t.job) end
  if is_valid_buf(t.buf) then pcall(api.nvim_buf_delete, t.buf, { force = true }) end
  state.terms[id] = nil
  if state.active == id then state.active = first_id() end
  if was_current then restore_focus() end
  refresh_highlights()
end

---Pick an existing terminal with vim.ui.select and reveal it.
function M.pick()
  local ids = sorted_ids()
  if #ids == 0 then
    vim.notify('FloatTerm: no terminals yet; opening a new one', vim.log.levels.INFO)
    return M.new()
  end

  local items = {}
  for _, id in ipairs(ids) do
    local t = state.terms[id]
    local label = ('term %d  [%s]'):format(id, is_valid_win(t.win) and 'visible' or 'hidden')
    if type(t.cmd) == 'string' and t.cmd ~= '' then
      label = label .. '  ' .. t.cmd
    elseif type(t.cmd) == 'table' then
      label = label .. '  ' .. table.concat(t.cmd, ' ')
    end
    items[#items + 1] = { id = id, label = label }
  end

  vim.ui.select(items, {
    prompt = 'Floating terminals',
    format_item = function(item) return item.label end,
  }, function(item)
    if item then M.show(item.id, true) end
  end)
end

---@return table<string, table>
function M.instances() return state.terms end

-- ---------------------------------------------------------------------------
-- Keymaps and commands
-- ---------------------------------------------------------------------------

local function set_keymaps()
  local km = state.opts.keymaps
  local function map(modes, lhs, rhs, desc)
    if lhs == false or lhs == nil or lhs == '' then return end
    vim.keymap.set(modes, lhs, rhs, { desc = 'FloatTerm: ' .. desc, silent = true })
  end

  map('n', km.new, function() M.new() end, 'new terminal')
  map({ 'n', 't' }, km.toggle, function() M.toggle() end, 'toggle terminal')
  map({ 'n', 't' }, km.toggle_alt, function() M.toggle() end, 'toggle terminal')
  map('n', km.toggle_all, function() M.toggle_all() end, 'toggle all terminals')
  map('n', km.focus_next, function() M.focus_next(1) end, 'focus next terminal')
  map('n', km.focus_prev, function() M.focus_next(-1) end, 'focus previous terminal')
  map({ 'n', 't' }, km.close, function() M.close() end, 'close terminal')
  map('n', km.pick, function() M.pick() end, 'pick terminal')

  map({ 'n', 't' }, km.move_left, function() move(0, -state.opts.move_step) end, 'move left')
  map({ 'n', 't' }, km.move_down, function() move(state.opts.move_step, 0) end, 'move down')
  map({ 'n', 't' }, km.move_up, function() move(-state.opts.move_step, 0) end, 'move up')
  map({ 'n', 't' }, km.move_right, function() move(0, state.opts.move_step) end, 'move right')

  map({ 'n', 't' }, km.resize_left, function() resize(-state.opts.resize_step, 0) end, 'shrink width')
  map({ 'n', 't' }, km.resize_right, function() resize(state.opts.resize_step, 0) end, 'grow width')
  map({ 'n', 't' }, km.resize_up, function() resize(0, -state.opts.resize_step) end, 'shrink height')
  map({ 'n', 't' }, km.resize_down, function() resize(0, state.opts.resize_step) end, 'grow height')

  if km.numbered then
    for i = 1, 9 do
      vim.keymap.set('n', km.numbered .. i, function() M.toggle(i) end, { desc = ('FloatTerm: toggle terminal %d'):format(i), silent = true })
    end
  end

  if state.opts.mouse then
    vim.keymap.set({ 'n', 't' }, '<LeftMouse>', function()
      if not mouse_down() then feed_default '<LeftMouse>' end
    end, { desc = 'FloatTerm: focus/move/resize float', silent = true })
    vim.keymap.set({ 'n', 't' }, '<LeftDrag>', function()
      if not mouse_drag() then feed_default '<LeftDrag>' end
    end, { desc = 'FloatTerm: drag float', silent = true })
    vim.keymap.set({ 'n', 't' }, '<LeftRelease>', function()
      if not mouse_release() then feed_default '<LeftRelease>' end
    end, { desc = 'FloatTerm: release float', silent = true })
  end
end

local function parse_id(arg)
  if arg == nil or arg == '' then return nil end
  local id = tonumber(arg)
  if not id then
    vim.notify(('FloatTerm: invalid terminal id %q'):format(arg), vim.log.levels.ERROR)
    return nil
  end
  return math.floor(id)
end

local function set_commands()
  api.nvim_create_user_command('FloatTerm', function(args) M.new(args.args ~= '' and args.args or nil) end, {
    nargs = '*',
    desc = 'Open a new floating terminal (optional command)',
    complete = 'shellcmd',
  })
  api.nvim_create_user_command('FloatTermToggle', function(args) M.toggle(parse_id(args.args)) end, {
    nargs = '?',
    desc = 'Toggle a floating terminal',
  })
  api.nvim_create_user_command('FloatTermToggleAll', function() M.toggle_all() end, {
    desc = 'Toggle all floating terminals',
  })
  api.nvim_create_user_command('FloatTermPick', function() M.pick() end, {
    desc = 'Pick a floating terminal',
  })
  api.nvim_create_user_command('FloatTermClose', function(args) M.close(parse_id(args.args)) end, {
    nargs = '?',
    desc = 'Close a floating terminal',
  })
  api.nvim_create_user_command('FloatTermNext', function() M.focus_next(1) end, {
    desc = 'Focus next floating terminal',
  })
end

---Configure the module. Safe to call more than once.
---@param opts? table
---@return table
function M.setup(opts)
  opts = opts or {}
  state.opts = vim.tbl_deep_extend('force', vim.deepcopy(defaults), opts)
  define_highlights()
  setup_autocmds()
  set_keymaps()
  set_commands()
  return M
end

return M
