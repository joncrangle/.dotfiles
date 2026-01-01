local M = {}

-- Cache for dynamic highlight groups
local hl_cache = {}

local function get_icon_hl(name, is_current)
  local suffix = is_current and 'Sel' or 'Norm'
  local hl_name = 'TabLineIcon' .. suffix .. name

  if hl_cache[hl_name] then
    return hl_name
  end

  -- Create the highlight group on demand
  local icon_hl = vim.api.nvim_get_hl(0, { name = name })
  local tab_hl_name = is_current and 'TabLineSel' or 'TabLine'
  local tab_hl = vim.api.nvim_get_hl(0, { name = tab_hl_name })

  if icon_hl and tab_hl then
    vim.api.nvim_set_hl(0, hl_name, {
      fg = icon_hl.fg,
      bg = tab_hl.bg,
      sp = tab_hl.sp,
      underline = tab_hl.underline,
      undercurl = tab_hl.undercurl,
      italic = tab_hl.italic,
      bold = tab_hl.bold,
    })
    hl_cache[hl_name] = true
    return hl_name
  end

  return name -- Fallback
end

function M.render()
  local tabcount = vim.fn.tabpagenr '$'
  if tabcount <= 1 then
    return ''
  end

  local s = '%#TabLineFill# 󰈙  '
  for i = 1, tabcount do
    local winnr = vim.fn.tabpagewinnr(i)
    local bufnr = vim.fn.tabpagebuflist(i)[winnr]
    local bufname = vim.fn.bufname(bufnr)
    local filename = vim.fn.fnamemodify(bufname, ':t')
    local ft = vim.bo[bufnr].filetype

    local icon, icon_hl = '', nil
    if _G.MiniIcons then
      if filename ~= '' then
        icon, icon_hl = MiniIcons.get('file', filename)
      elseif ft ~= '' then
        icon, icon_hl = MiniIcons.get('filetype', ft)
        filename = ft
      else
        filename = '[No Name]'
      end
    else
      filename = filename ~= '' and filename or '[No Name]'
    end

    local is_current = i == vim.fn.tabpagenr()
    local is_modified = vim.fn.getbufvar(bufnr, '&mod') == 1
    local tab_hl = is_current and '%#TabLineSel#' or '%#TabLine#'

    s = s .. tab_hl .. ' ' .. i .. ' '

    if icon_hl and icon ~= '' then
      -- Use custom composite highlight
      local composite_hl = get_icon_hl(icon_hl, is_current)
      s = s .. '%#' .. composite_hl .. '#' .. icon .. ' ' .. tab_hl
    end

    if is_modified then
      s = s .. '%#MatchParen#'
    end
    s = s .. filename .. ' ' .. tab_hl
  end

  return s .. '%#TabLineFill#%T'
end

_G.CustomTabline = M.render
vim.o.tabline = '%!v:lua.CustomTabline()'
vim.o.showtabline = 1

-- Clear cache on colorscheme change
vim.api.nvim_create_autocmd('ColorScheme', {
  callback = function()
    hl_cache = {}
  end,
})

return M
-- vim: ts=2 sts=2 sw=2 et
