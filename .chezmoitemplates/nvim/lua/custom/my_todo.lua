local M = {}

local ns = vim.api.nvim_create_namespace 'my_todo'

local keywords = {
  TODO = 'TODO',
  FIXME = 'FIX',
  FIX = 'FIX',
  BUG = 'FIX',
  FIXIT = 'FIX',
  ISSUE = 'FIX',

  HACK = 'HACK',

  WARN = 'WARN',
  WARNING = 'WARN',
  XXX = 'WARN',

  NOTE = 'NOTE',
  INFO = 'NOTE',
  README = 'NOTE',
  PERF = 'PERF',
  OPTIMIZE = 'PERF',
  PERFORMANCE = 'PERF',
}

local kind_links = {
  TODO = 'DiagnosticInfo',
  FIX = 'DiagnosticError',
  HACK = 'DiagnosticWarn',
  WARN = 'DiagnosticWarn',
  NOTE = 'DiagnosticHint',
  PERF = 'DiagnosticHint',
}

-- Only used if the active colorscheme doesn't set an explicit fg on the
-- linked Diagnostic group.
local kind_fallback = {
  TODO = 0x89b4fa,
  FIX = 0xf38ba8,
  HACK = 0xcba6f7,
  WARN = 0xf9e2af,
  NOTE = 0x94e2d5,
  PERF = 0x94e2d5,
}

local function get_fg(hl_name)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = hl_name, link = false })
  if ok and hl then
    return hl.fg
  end
  return nil
end

local function luminance(rgb)
  local r = math.floor(rgb / 0x10000) % 0x100
  local g = math.floor(rgb / 0x100) % 0x100
  local b = rgb % 0x100
  return (0.299 * r + 0.587 * g + 0.114 * b) / 255
end

local function contrast(rgb)
  if luminance(rgb) > 0.5 then
    return 0x000000
  end
  return 0xffffff
end

local function setup_highlights()
  for kind, link in pairs(kind_links) do
    local color = get_fg(link) or kind_fallback[kind]

    -- Message text in the comment: colored, no background.
    vim.api.nvim_set_hl(0, 'TodoFg' .. kind, {
      fg = color,
    })

    -- Keyword badge: reversed so it reads as a pill.
    vim.api.nvim_set_hl(0, 'TodoBg' .. kind, {
      fg = contrast(color),
      bg = color,
      bold = true,
    })
  end
end

local function get_comment_node(bufnr, row, col)
  local ok, node = pcall(vim.treesitter.get_node, {
    bufnr = bufnr,
    pos = { row, col },
  })

  if not ok then
    return nil
  end

  while node do
    if node:type() == 'comment' then
      return node
    end
    node = node:parent()
  end
end

-- Extend forward through subsequent sibling `comment` nodes that are
-- contiguous (no gap row between them), so a run of consecutive
-- single-line `--`/`#`/`//` comments highlights as one block, the same
-- way a genuine multiline `/* */`-style node already does on its own.
local function extend_multiline(node, er, ec)
  local sibling = node:next_named_sibling()

  while sibling and sibling:type() == 'comment' do
    local nsr, _, ner, nec = sibling:range()

    if nsr ~= er + 1 then
      break -- gap (blank line or intervening code) — stop here
    end

    er, ec = ner, nec
    sibling = sibling:next_named_sibling()
  end

  return er, ec
end

local function add_keyword(bufnr, row, start_col, end_col, kind)
  vim.api.nvim_buf_set_extmark(bufnr, ns, row, start_col, {
    end_row = row,
    end_col = end_col,
    hl_group = 'TodoBg' .. kind,
    priority = 200,
  })
end

local function add_comment(bufnr, kind, kw_row, kw_end_col, node)
  local _, _, er, ec = node:range()
  er, ec = extend_multiline(node, er, ec)

  -- Start right after the keyword (not at the comment's own start), so
  -- the delimiter and any text before the keyword keep their normal
  -- comment color. Priority > treesitter's own @comment highlight (100)
  -- so this reliably wins, including across the whole multiline span.
  vim.api.nvim_buf_set_extmark(bufnr, ns, kw_row, kw_end_col, {
    end_row = er,
    end_col = ec,
    hl_group = 'TodoFg' .. kind,
    priority = 110,
  })
end

local function scan(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for row, line in ipairs(lines) do
    local search_from = 1

    while search_from <= #line do
      local match_start, match_end, kind

      for word, k in pairs(keywords) do
        local s, e = line:find('%f[%w]' .. word .. '%f[%W]', search_from)
        if s and (not match_start or s < match_start) then
          match_start, match_end, kind = s, e, k
        end
      end

      if not match_start then
        break
      end

      local start_col = match_start - 1
      local kw_row = row - 1

      -- Only highlight keywords that are actually inside a comment.
      local node = get_comment_node(bufnr, kw_row, start_col)

      if node then
        add_keyword(bufnr, kw_row, start_col, match_end, kind)
        add_comment(bufnr, kind, kw_row, match_end, node)
      end

      search_from = match_end + 1
    end
  end
end

-- Debounce: TextChangedI fires on nearly every keystroke, so without
-- coalescing, a burst of typing queues up one full-buffer rescan per
-- keystroke. Collapse bursts into a single scan shortly after typing
-- pauses.
local timers = {}

local function schedule_scan(bufnr)
  local timer = timers[bufnr]

  if not timer then
    timer = vim.uv.new_timer()
    if not timer then
      -- Couldn't allocate a timer handle (rare). Fall back to an
      -- immediate, non-debounced scan rather than dropping the update.
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(bufnr) then
          scan(bufnr)
        end
      end)
      return
    end
    timers[bufnr] = timer
  end

  timer:stop()
  timer:start(150, 0, function()
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(bufnr) then
        scan(bufnr)
      end
    end)
  end)
end

function M.setup()
  setup_highlights()

  local group = vim.api.nvim_create_augroup('my_todo', {})

  vim.api.nvim_create_autocmd('ColorScheme', {
    group = group,
    callback = setup_highlights,
  })

  vim.api.nvim_create_autocmd({
    'BufEnter',
    'TextChanged',
    'TextChangedI',
    'BufWritePost',
  }, {
    group = group,
    callback = function(args)
      schedule_scan(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd('BufDelete', {
    group = group,
    callback = function(args)
      local timer = timers[args.buf]
      if timer then
        timer:stop()
        timer:close()
        timers[args.buf] = nil
      end
    end,
  })
end

return M
