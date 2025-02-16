---@class VisualLineNumbersOptions
---@field fg string?
---@field bg string?
---@field highlight_group string?
---@field priority number?
---@field debounce_ms number?
local M = {}

local function get_warning_fg()
  local hl = vim.api.nvim_get_hl(0, { name = 'CursorLineNr' })
  return hl.fg or 'NONE'
end

local defaults = {
  fg = get_warning_fg(),
  bg = 'NONE',
  highlight_group = 'VisualLineNr',
  priority = 10,
  debounce_ms = 10,
}

local options = {}
local initialized = false
local last_range = { start = nil, finish = nil }
local ns_id = vim.api.nvim_create_namespace('visual_line_numbers')

local function init()
  if initialized then
    return
  end
  initialized = true

  local ok, err = pcall(function()
    vim.api.nvim_set_hl(0, options.highlight_group, { fg = options.fg, bg = options.bg })
  end)
  if not ok then
    vim.notify('Error setting highlight group: ' .. tostring(err), vim.log.levels.ERROR)
  end

  local function update_highlights()
    local current_mode = vim.fn.mode()
    if not current_mode:match('[vV\x16]') then
      if last_range.start and last_range.finish then
        vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
      end
      last_range = { start = nil, finish = nil }
      return
    end

    local start_line = vim.fn.line('v')
    local end_line = vim.fn.line('.')
    if start_line > end_line then
      start_line, end_line = end_line, start_line
    end

    if last_range.start == start_line and last_range.finish == end_line then
      return
    end
    last_range = { start = start_line, finish = end_line }

    for line = start_line, end_line do
      vim.api.nvim_buf_set_extmark(0, ns_id, line - 1, 0, {
        number_hl_group = options.highlight_group,
        priority = options.priority,
      })
    end
  end

  local function debounced_update()
    vim.defer_fn(update_highlights, options.debounce_ms)
  end

  local function setup_autocmds()
    local group = vim.api.nvim_create_augroup('VisualLineNumbers', { clear = true })

    vim.api.nvim_create_autocmd('ColorScheme', {
      group = group,
      callback = function()
        local success, error_msg = pcall(function()
          vim.api.nvim_set_hl(0, options.highlight_group, { fg = options.fg, bg = options.bg })
        end)
        if not success then
          vim.notify('Error setting highlight group: ' .. tostring(error_msg), vim.log.levels.ERROR)
        end
      end
    })

    vim.api.nvim_create_autocmd({ 'ModeChanged', 'CursorMoved', 'TextChanged', 'TextChangedI' }, {
      group = group,
      callback = debounced_update,
    })

    vim.api.nvim_create_autocmd({ 'BufLeave', 'ModeChanged' }, {
      group = group,
      pattern = { '*', '[vV\x16]*:*' },
      callback = function()
        vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
      end
    })
  end

  setup_autocmds()
end

---@param opts VisualLineNumbersOptions|{}
M.setup = function(opts)
  options = vim.tbl_deep_extend('force', defaults, opts or {})

  vim.api.nvim_create_autocmd("ModeChanged", {
    pattern = "*:[vV\x16]*",
    once = true,
    callback = init,
  })
end

return M
-- vim: ts=2 sts=2 sw=2 et
