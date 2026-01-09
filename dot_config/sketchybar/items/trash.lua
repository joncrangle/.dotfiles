local colors = require 'colors'
local settings = require 'settings'

-- Execute the trash_monitor binary which provides the count of items in the trash
sbar.exec '$CONFIG_DIR/trash/trash_monitor &'

local ICON_TRASH_EMPTY = ''
local ICON_TRASH_FULL = ''

local trash = sbar.add('item', 'trash', {
  position = 'right',
  icon = {
    font = {
      family = settings.font.numbers,
    },
    padding_right = 0,
  },
  label = {
    font = {
      family = settings.font.text,
    },
    drawing = false,
  },
})

local function update_trash(env)
  -- Read the count from the TRASH_COUNT variable sent by trash_monitor
  local count = tonumber(env.TRASH_COUNT)

  if count == 0 then
    -- Trash is empty
    trash:set {
      icon = {
        string = ICON_TRASH_EMPTY,
        color = colors.overlay0,
      },
      label = { drawing = false },
    }
  else
    trash:set {
      icon = {
        string = ICON_TRASH_FULL,
        color = colors.red,
      },
      label = {
        string = tostring(count),
        color = colors.red,
        drawing = true,
      },
    }
  end
end

trash:subscribe('trash_change', update_trash)

-- Add a click event to open the trash folder
trash:subscribe('mouse.clicked', function()
  sbar.exec 'open ~/.Trash'
end)

-- Get the initial state on load/reload
local function get_initial_state()
  sbar.exec('$CONFIG_DIR/trash/trash_monitor --count', function(count)
    if count then
      update_trash { TRASH_COUNT = count }
    end
  end)
end

get_initial_state()
