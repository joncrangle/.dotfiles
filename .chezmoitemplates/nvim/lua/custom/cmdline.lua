local M = {}

local function get_icon(firstc, content)
  if firstc == '/' or firstc == '?' then
    return ' ', vim.api.nvim_get_hl_id_by_name 'DiagnosticSignWarn'
  elseif firstc == '=' then
    return ' ', vim.api.nvim_get_hl_id_by_name 'DiagnosticSignInfo'
  elseif firstc == ':' then
    local str = ''
    for _, chunk in ipairs(content) do
      str = str .. chunk[2]
    end
    if str:match '^%s*lua[%s=]' or str:match '^%s*=' then
      return ' ', vim.api.nvim_get_hl_id_by_name 'DiagnosticSignInfo'
    elseif str:match '^%s*!' then
      return ' ', vim.api.nvim_get_hl_id_by_name 'DiagnosticSignWarn'
    elseif str:match '^%s*he?l?p?%s+' then
      return ' ', vim.api.nvim_get_hl_id_by_name 'DiagnosticSignHint'
    end
    return ' ', vim.api.nvim_get_hl_id_by_name 'DiagnosticSignInfo'
  end
  return firstc, 0
end

local function find_upvalue(fn, name)
  local i = 1
  while true do
    local n, val = debug.getupvalue(fn, i)
    if not n then
      return nil
    end
    if n == name then
      return i, val
    end
    i = i + 1
  end
end

function M.setup()
  local ok, ui = pcall(require, 'vim._core.ui2')
  if not ok then
    return
  end

  ui.enable {
    msg = {
      targets = 'msg',
    },
  }

  local ignored_messages = {
    '%d+ fewer lines',
    '%d+ more lines',
    'lines yanked$',
  }
  local orig_msg_show = ui.msg.msg_show
  ui.msg.msg_show = function(kind, content, replace_last, history, append, id, trigger)
    local str = ''
    for _, chunk in ipairs(content or {}) do
      str = str .. (chunk[2] or '')
    end
    for _, pat in ipairs(ignored_messages) do
      if str:match(pat) then
        return
      end
    end
    return orig_msg_show(kind, content, replace_last, history, append, id, trigger)
  end

  local orig_set_pos = ui.msg.set_pos
  ---@diagnostic disable-next-line: duplicate-set-field
  ui.msg.set_pos = function(tgt)
    orig_set_pos(tgt)
    local win = ui.wins and ui.wins.msg
    if win and vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_set_config, win, { border = 'none' })
    end
  end

  local cmd = require 'vim._core.ui2.cmdline'

  local show_idx, orig_win_config = find_upvalue(cmd.cmdline_show, 'win_config')
  local hide_idx = find_upvalue(cmd.cmdline_hide, 'win_config')

  local function custom_win_config(win, hide, height)
    if ui.cmdheight == 0 then
      local ok_cfg, cfg = pcall(vim.api.nvim_win_get_config, win)
      if ok_cfg and (cfg.hide ~= hide or cfg.row ~= 0) then
        pcall(vim.api.nvim_win_set_config, win, {
          hide = hide,
          height = not hide and height or nil,
          relative = 'laststatus',
          row = 0,
          col = 0,
        })
      elseif ok_cfg and not hide and vim.api.nvim_win_get_height(win) ~= height then
        pcall(vim.api.nvim_win_set_height, win, height)
      end
      return
    end
    if orig_win_config then
      return orig_win_config(win, hide, height)
    end
  end

  if show_idx then
    debug.setupvalue(cmd.cmdline_show, show_idx, custom_win_config)
  end
  if hide_idx then
    debug.setupvalue(cmd.cmdline_hide, hide_idx, custom_win_config)
  end

  local orig_show = cmd.cmdline_show
  cmd.cmdline_show = function(content, pos, firstc, prompt, indent, level, hl_id)
    local icon, icon_hl = get_icon(firstc, content)
    orig_show(content, pos, icon, prompt, indent, level, icon_hl > 0 and icon_hl or hl_id)
  end
end

return M
-- vim: ts=2 sts=2 sw=2 et
