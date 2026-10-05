local M = {
  last_win = nil,
}

local ns_scrollbar = vim.api.nvim_create_namespace 'hover_scrollbar'

local function ensure_highlights()
  local border = vim.api.nvim_get_hl(0, {
    name = 'FloatBorder',
    link = false,
  })

  local thumb_color = border.fg

  vim.api.nvim_set_hl(0, 'HoverScrollbarThumb', {
    fg = thumb_color,
    bg = thumb_color,
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'HoverScrollbarTrack', {
    default = true,
    link = 'FloatBorder',
  })
end

local function is_preview_win(win)
  return win and vim.api.nvim_win_is_valid(win) and not vim.w[win].is_scrollbar and (vim.w[win].lsp_floating_bufnr or vim.w[win]['textDocument/hover'])
end

local function get_preview_win()
  if is_preview_win(M.last_win) then
    return M.last_win
  end

  M.last_win = nil

  local cur_win = vim.api.nvim_get_current_win()

  if is_preview_win(cur_win) then
    local cfg = vim.api.nvim_win_get_config(cur_win)

    if cfg.relative ~= '' then
      return cur_win
    end
  end

  local cur_buf = vim.api.nvim_get_current_buf()
  local fwin = vim.b[cur_buf].lsp_floating_preview

  if is_preview_win(fwin) then
    return fwin
  end

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if is_preview_win(win) then
      local cfg = vim.api.nvim_win_get_config(win)

      if cfg.relative ~= '' and cfg.focusable ~= false then
        return win
      end
    end
  end

  return nil
end

local function has_border(win)
  local cfg = vim.api.nvim_win_get_config(win)
  local border = cfg.border

  if border == nil then
    border = vim.o.winborder
  end

  if border == nil or border == '' or border == 'none' then
    return false
  end

  if type(border) == 'table' then
    return #border > 0
  end

  return true
end

local function close_scrollbar(win)
  if not win or not vim.api.nvim_win_is_valid(win) then
    return
  end

  local sb_win = vim.w[win].scrollbar_win

  if sb_win and vim.api.nvim_win_is_valid(sb_win) then
    pcall(vim.api.nvim_win_close, sb_win, true)
  end

  vim.w[win].scrollbar_win = nil
end

local function scrollbar_config(win, height, width)
  local cfg = vim.api.nvim_win_get_config(win)
  local bordered = has_border(win)

  -- Attach the scrollbar directly to the hover window.
  --
  -- For a bordered float, relative='win' coordinates are relative to the
  -- inner window grid, so col=width lands on the right border.
  --
  -- Without a border there is no outer cell to occupy, so use the final
  -- content column instead.
  return {
    relative = 'win',
    win = win,
    anchor = 'NW',
    row = 0,
    col = width - (bordered and 0 or 1),
    width = 1,
    height = height,
    focusable = false,
    mouse = false,
    style = 'minimal',
    border = 'none',
    zindex = (cfg.zindex or 50) + 1,
  }
end

function M.render_scrollbar(win)
  if not win or not vim.api.nvim_win_is_valid(win) then
    return
  end

  local height = vim.api.nvim_win_get_height(win)
  local width = vim.api.nvim_win_get_width(win)
  local buf = vim.api.nvim_win_get_buf(win)

  local line_count = vim.api.nvim_buf_line_count(buf)

  local text_h = 0
  local ok_th, th_all = pcall(function()
    return vim.api.nvim_win_text_height(win, {}).all
  end)

  if ok_th and type(th_all) == 'number' then
    text_h = th_all
  end

  local total = math.max(text_h, line_count)

  if total <= height then
    close_scrollbar(win)
    return
  end

  local view = vim.api.nvim_win_call(win, vim.fn.winsaveview)

  local ok_rem, rem_th = pcall(function()
    return vim.api.nvim_win_text_height(win, {
      start_row = view.topline - 1,
      start_vcol = view.skipcol or 0,
    }).all
  end)

  local remaining = (ok_rem and type(rem_th) == 'number' and rem_th or total - view.topline + 1)

  local scrolled = math.max(0, total - remaining)
  local max_scroll = math.max(1, total - height)
  local ratio = math.min(1, scrolled / max_scroll)

  local thumb_height = math.max(1, math.min(height, math.floor(height * (height / total) + 0.5)))

  local thumb_offset = math.floor(ratio * (height - thumb_height) + 0.5)

  local bar_lines = {}

  for i = 1, height do
    if i >= thumb_offset + 1 and i <= thumb_offset + thumb_height then
      bar_lines[i] = '█'
    else
      bar_lines[i] = '│'
    end
  end

  local sb_win = vim.w[win].scrollbar_win
  local sb_buf
  local config = scrollbar_config(win, height, width)

  if sb_win and vim.api.nvim_win_is_valid(sb_win) then
    sb_buf = vim.api.nvim_win_get_buf(sb_win)

    vim.api.nvim_win_set_config(sb_win, config)
  else
    sb_buf = vim.api.nvim_create_buf(false, true)

    vim.bo[sb_buf].buftype = 'nofile'
    vim.bo[sb_buf].bufhidden = 'wipe'
    vim.bo[sb_buf].swapfile = false

    config.noautocmd = true

    sb_win = vim.api.nvim_open_win(sb_buf, false, config)

    vim.wo[sb_win].winhighlight = 'Normal:HoverScrollbarTrack'

    vim.wo[sb_win].winblend = 0
    vim.wo[sb_win].foldenable = false
    vim.wo[sb_win].wrap = false
    vim.wo[sb_win].cursorline = false

    vim.w[sb_win].is_scrollbar = true
    vim.w[win].scrollbar_win = sb_win

    vim.api.nvim_create_autocmd('WinClosed', {
      pattern = tostring(win),
      once = true,

      callback = function()
        if M.last_win == win then
          M.last_win = nil
        end

        if vim.api.nvim_win_is_valid(sb_win) then
          pcall(vim.api.nvim_win_close, sb_win, true)
        end
      end,
    })
  end

  vim.bo[sb_buf].modifiable = true

  vim.api.nvim_buf_set_lines(sb_buf, 0, -1, false, bar_lines)

  vim.bo[sb_buf].modifiable = false

  vim.api.nvim_buf_clear_namespace(sb_buf, ns_scrollbar, 0, -1)

  for i = 1, height do
    local is_thumb = i >= thumb_offset + 1 and i <= thumb_offset + thumb_height

    vim.api.nvim_buf_set_extmark(sb_buf, ns_scrollbar, i - 1, 0, {
      end_col = #bar_lines[i],
      hl_group = is_thumb and 'HoverScrollbarThumb' or 'HoverScrollbarTrack',
    })
  end
end

function M.scroll(delta)
  local fwin = get_preview_win()

  if not fwin then
    return false
  end

  vim.api.nvim_win_call(fwin, function()
    vim.wo.scrolloff = 0
    vim.wo.sidescrolloff = 0

    local height = vim.api.nvim_win_get_height(0)
    local view = vim.fn.winsaveview()

    if delta > 0 then
      local th = vim.api.nvim_win_text_height(0, {
        start_row = view.topline - 1,
        start_vcol = view.skipcol or 0,
      })

      local max_scroll = math.max(0, th.all - height)

      local step = math.min(delta, max_scroll)

      if step > 0 then
        vim.cmd('normal! ' .. step .. '\x05')
      end
    elseif delta < 0 then
      if view.topline > 1 or (view.skipcol or 0) > 0 then
        vim.cmd('normal! ' .. math.abs(delta) .. '\x19')
      end
    end
  end)

  M.render_scrollbar(fwin)

  return true
end

function M.dismiss()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) then
      if vim.w[win].is_scrollbar or vim.w[win].lsp_floating_bufnr or vim.w[win]['textDocument/hover'] then
        pcall(vim.api.nvim_win_close, win, true)
      end
    end
  end

  M.last_win = nil
end

function M.setup()
  ensure_highlights()

  vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('hover-scrollbar-highlights', { clear = true }),

    callback = ensure_highlights,
  })

  local orig_open = vim.lsp.util.open_floating_preview

  ---@diagnostic disable-next-line: duplicate-set-field
  vim.lsp.util.open_floating_preview = function(contents, syntax, opts)
    opts = opts or {}

    if not opts.height and type(contents) == 'table' and #contents > 0 then
      local min_h = 5
      local max_h = 12

      local h = math.max(min_h, math.min(#contents, max_h))

      local lines_above = vim.fn.winline() - 1

      local lines_below = vim.fn.winheight(0) - vim.fn.winline()

      if h > lines_below and lines_above > lines_below then
        opts.anchor_bias = 'above'
      end

      local max_w = 50

      for _, line in ipairs(contents) do
        max_w = math.max(max_w, vim.fn.strdisplaywidth(line))
      end

      opts.width = math.max(50, math.min(opts.max_width or 90, max_w + 2))

      opts.height = h
    end

    local fbuf, fwin = orig_open(contents, syntax, opts)

    if fwin and vim.api.nvim_win_is_valid(fwin) then
      M.last_win = fwin

      vim.wo[fwin].scrolloff = 0
      vim.wo[fwin].sidescrolloff = 0

      -- The scrollbar is relative to this float itself, so it can be
      -- rendered correctly immediately. No delayed geometry correction
      -- is required.
      M.render_scrollbar(fwin)
    end

    return fbuf, fwin
  end

  vim.api.nvim_create_autocmd('WinScrolled', {
    group = vim.api.nvim_create_augroup('hover-scroll-sync', { clear = true }),

    callback = function()
      local win = get_preview_win()

      if win and vim.api.nvim_win_is_valid(win) then
        M.render_scrollbar(win)
      end
    end,
  })

  vim.api.nvim_create_autocmd('CmdlineEnter', {
    group = vim.api.nvim_create_augroup('hover-cmdline-dismiss', { clear = true }),

    callback = M.dismiss,
  })

  vim.keymap.set({ 'n', 's' }, '<C-f>', function()
    if not M.scroll(4) then
      vim.cmd 'normal! \x06'
    end
  end, {
    desc = 'Scroll hover doc or page down',
  })

  vim.keymap.set({ 'n', 's' }, '<C-b>', function()
    if not M.scroll(-4) then
      vim.cmd 'normal! \x02'
    end
  end, {
    desc = 'Scroll hover doc or page up',
  })

  vim.keymap.set('i', '<C-f>', function()
    if not M.scroll(4) then
      local key = vim.api.nvim_replace_termcodes('<C-f>', true, false, true)

      vim.api.nvim_feedkeys(key, 'n', false)
    end
  end, {
    desc = 'Scroll hover doc forward',
  })

  vim.keymap.set('i', '<C-b>', function()
    if not M.scroll(-4) then
      local key = vim.api.nvim_replace_termcodes('<C-b>', true, false, true)

      vim.api.nvim_feedkeys(key, 'n', false)
    end
  end, {
    desc = 'Scroll hover doc backward',
  })
end

return M
-- vim: ts=2 sts=2 sw=2 et
