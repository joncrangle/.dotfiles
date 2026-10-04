local colors = require 'colors'
local settings = require 'settings'

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
  local count = tonumber(env.TRASH_COUNT)

  if not count then
    return
  end

  if count == 0 then
    trash:set {
      icon = {
        string = ICON_TRASH_EMPTY,
        color = colors.overlay0,
      },
      label = {
        drawing = false,
      },
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

-- Subscribe before starting the monitor so its initial trash_change event
-- cannot be missed.
trash:subscribe('trash_change', update_trash)

trash:subscribe('mouse.clicked', function()
  sbar.exec 'open ~/.Trash'
end)

-- Start the trash monitor.
--
-- On first launch, it becomes the persistent monitor and immediately sends the
-- current trash count.
--
-- On a SketchyBar reload, if the monitor is already running, this invocation
-- detects the existing instance, sends the current count to the newly reloaded
-- SketchyBar, and exits.
sbar.exec '$CONFIG_DIR/trash/trash_monitor &'
