-- lua/config/buffers.lua
-- Layout-preserving buffer close shared by the <leader>bd keymap and the
-- bufferline close paths (x icon, middle click, close others/right).
--
-- Why not plain :bdelete: it closes the window showing the buffer. mini.bufremove
-- unshows the buffer from every window first, so splits and the overall layout
-- survive. Modified buffers always go through an explicit Save/Discard/Cancel
-- prompt; nothing is ever discarded silently.

local M = {}

local api = vim.api

---A floating terminal buffer must never be closed by buffer/tab actions.
---@param buf integer
---@return boolean
function M.is_protected(buf)
  if not api.nvim_buf_is_valid(buf) then return true end
  if vim.b[buf].floatterm_id ~= nil then return true end
  return vim.bo[buf].buftype == 'terminal'
end

---@param buf integer
---@return string
local function display_name(buf)
  local name = api.nvim_buf_get_name(buf)
  if name == '' then return ('buffer %d'):format(buf) end
  return vim.fn.fnamemodify(name, ':~:.')
end

---Ask about unsaved changes.
---@param buf integer
---@return boolean proceed
---@return boolean force
local function confirm_modified(buf)
  local has_name = api.nvim_buf_get_name(buf) ~= ''
  local choices = has_name and '&Save\n&Discard\n&Cancel' or '&Discard\n&Cancel'
  local default = 1
  local choice = vim.fn.confirm(('Save changes to %s?'):format(display_name(buf)), choices, default, 'Question')

  if has_name then
    if choice == 1 then
      local ok, err = pcall(function()
        api.nvim_buf_call(buf, function() vim.cmd.write() end)
      end)
      if not ok then
        vim.notify('buffers: save failed: ' .. tostring(err), vim.log.levels.ERROR)
        return false, false
      end
      return true, false
    elseif choice == 2 then
      return true, true
    end
    return false, false
  end

  if choice == 1 then return true, true end
  return false, false
end

---Close a buffer without disturbing the window layout.
---@param buf? integer Buffer to close; nil/0 means the current buffer.
---@param opts? { force?: boolean, quiet?: boolean }
---@return boolean closed
function M.close(buf, opts)
  opts = opts or {}
  buf = (buf == nil or buf == 0) and api.nvim_get_current_buf() or buf

  if not api.nvim_buf_is_valid(buf) then return false end
  if M.is_protected(buf) then
    if not opts.quiet then vim.notify('buffers: refusing to close a floating terminal buffer', vim.log.levels.WARN) end
    return false
  end
  -- Only real file buffers are closeable here; help/quickfix/etc. are not tabs.
  if vim.bo[buf].buftype ~= '' then return false end

  local force = opts.force == true
  if not force and vim.bo[buf].modified then
    local proceed, discard = confirm_modified(buf)
    if not proceed then return false end
    force = discard
  end

  local ok, bufremove = pcall(require, 'mini.bufremove')
  if ok then return bufremove.delete(buf, force) ~= false end

  -- Fallback if mini.nvim is unavailable: replace the buffer in every window
  -- before deleting it, which keeps splits alive.
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if api.nvim_win_is_valid(win) then
      local alt = vim.fn.bufnr('#')
      if alt ~= buf and vim.fn.buflisted(alt) == 1 then
        api.nvim_win_set_buf(win, alt)
      else
        api.nvim_win_set_buf(win, api.nvim_create_buf(true, false))
      end
    end
  end
  local deleted, err = pcall(api.nvim_buf_delete, buf, { force = force })
  if not deleted then
    vim.notify('buffers: delete failed: ' .. tostring(err), vim.log.levels.ERROR)
    return false
  end
  return true
end

return M
