local colors = require 'colors'
local app_icons = require 'app_icons'
local settings = require 'settings'

local whitelist = {
  ['com.spotify.client'] = 'Spotify',
  ['com.apple.Music'] = 'Music',
  ['com.apple.podcasts'] = 'Podcasts',
  ['org.videolan.vlc'] = 'VLC',
  ['com.colliderli.iina'] = 'IINA',
  ['net.imput.helium'] = 'Helium',
  ['com.google.Chrome'] = 'Google Chrome',
  ['org.mozilla.com.zen.browser'] = 'Zen Browser',
  ['app.zen-browser.zen'] = 'Zen Browser',
  ['com.apple.QuickTimePlayerX'] = 'QuickTime Player',
}

local media = sbar.add('item', 'media', {
  icon = {
    font = 'sketchybar-app-font:Regular:12.0',
    color = colors.green,
  },
  label = {
    font = { family = settings.font.numbers, size = 12.0 },
    width = 250,
    max_chars = 30,
    scroll_duration = 400,
    padding_right = 12,
    color = colors.green,
    background = {
      color = colors.with_alpha(colors.surface0, 0),
      corner_radius = 10,
      height = 24,
    },
  },
  scroll_texts = true,
  position = 'center',
  updates = true,
  color = colors.green,
  background = {
    color = colors.with_alpha(colors.surface0, 0),
    corner_radius = 10,
    height = 24,
  },
  drawing = 'off',
})

media:subscribe('mouse.clicked', function()
  sbar.exec 'media-control toggle-play-pause'
end)

sbar.add('event', 'media_update')

-- State cache to accumulate partial updates
local state = {
  app = '',
  title = '',
  artist = '',
  album = '',
  playing = false,
}

-- View cache to prevent unnecessary redraws
local last_view = {
  icon = nil,
  label = nil,
  drawing = false,
  bg_color = nil,
}

-- Listener script using jq for JSON parsing
local listener_cmd = [[
killall media-control >/dev/null 2>&1
sleep 0.1

# State cache
LAST_APP=""
LAST_TITLE=""
LAST_ARTIST=""
LAST_ALBUM=""
LAST_PLAYING="false"

# Sent state to detect changes
SENT_APP=""
SENT_TITLE=""
SENT_ARTIST=""
SENT_ALBUM=""
SENT_PLAYING=""

media-control stream | while IFS= read -r line; do
  # Parse all fields in a single jq call
  eval $(echo "$line" | jq -r '
    if .payload | length == 0 then
      "IS_EMPTY=true"
    else
      .payload | 
      "IS_EMPTY=false" +
      (if .bundleIdentifier then " NEW_APP=\"" + .bundleIdentifier + "\"" else "" end) +
      (if .playing != null then " NEW_PLAYING=\"" + (.playing | tostring) + "\"" else "" end) +
      (if .title then " NEW_TITLE=\"" + (.title | gsub("\""; "\\\"")) + "\"" else "" end) +
      (if .artist then " NEW_ARTIST=\"" + (.artist | gsub("\""; "\\\"")) + "\"" else "" end) +
      (if .album then " NEW_ALBUM=\"" + (.album | gsub("\""; "\\\"")) + "\"" else "" end)
    end
  ')
  
  if [ "$IS_EMPTY" = "true" ]; then
    if [ "$SENT_APP" != "" ]; then
      sketchybar --trigger media_update STATE=stopped
      SENT_APP=""
      SENT_TITLE=""
      SENT_ARTIST=""
      SENT_ALBUM=""
      SENT_PLAYING=""
    fi
    continue
  fi
  
  # Update cache only if new value exists
  [ -n "$NEW_APP" ] && LAST_APP="$NEW_APP"
  [ -n "$NEW_PLAYING" ] && LAST_PLAYING="$NEW_PLAYING"
  [ -n "$NEW_TITLE" ] && LAST_TITLE="$NEW_TITLE"
  [ -n "$NEW_ARTIST" ] && LAST_ARTIST="$NEW_ARTIST"
  [ -n "$NEW_ALBUM" ] && LAST_ALBUM="$NEW_ALBUM"
  
  # Only trigger if something actually changed
  if [ "$LAST_APP" != "$SENT_APP" ] || \
     [ "$LAST_TITLE" != "$SENT_TITLE" ] || \
     [ "$LAST_ARTIST" != "$SENT_ARTIST" ] || \
     [ "$LAST_ALBUM" != "$SENT_ALBUM" ] || \
     [ "$LAST_PLAYING" != "$SENT_PLAYING" ]; then
    
    sketchybar --trigger media_update \
      APP="$LAST_APP" \
      TITLE="$LAST_TITLE" \
      ARTIST="$LAST_ARTIST" \
      ALBUM="$LAST_ALBUM" \
      PLAYING="$LAST_PLAYING"
    
    SENT_APP="$LAST_APP"
    SENT_TITLE="$LAST_TITLE"
    SENT_ARTIST="$LAST_ARTIST"
    SENT_ALBUM="$LAST_ALBUM"
    SENT_PLAYING="$LAST_PLAYING"
  fi
done &
]]

sbar.exec(listener_cmd)

media:subscribe('media_update', function(env)
  -- Handle stopped state
  if env.STATE == 'stopped' then
    if last_view.drawing then
      sbar.exec 'sketchybar --set media drawing=off --set media.spacer width=0'
      last_view.drawing = false
    end
    return
  end

  -- Update state cache
  if env.APP and env.APP ~= '' then
    state.app = env.APP
  end
  if env.TITLE and env.TITLE ~= '' then
    state.title = env.TITLE
  end
  if env.ARTIST and env.ARTIST ~= '' then
    state.artist = env.ARTIST
  end
  if env.ALBUM and env.ALBUM ~= '' then
    state.album = env.ALBUM
  end
  if env.PLAYING then
    state.playing = (env.PLAYING == 'true')
  end

  -- Check if app is whitelisted
  local app_name = whitelist[state.app]
  if not app_name then
    if last_view.drawing then
      sbar.exec 'sketchybar --set media drawing=off --set media.spacer width=0'
      last_view.drawing = false
    end
    return
  end

  -- Build display
  local lookup = app_icons[app_name]
  local icon = (lookup == nil) and app_icons['default'] or lookup
  local playback_icon = state.playing and '' or ''
  local artist = (state.artist ~= '') and state.artist or 'Unknown Artist'
  local title = (state.title ~= '') and state.title or 'Unknown Title'
  local label = playback_icon .. ' ' .. artist .. ': ' .. title
  local bg_color = colors.surface0

  -- Only update if something visually changed
  if last_view.icon ~= icon or last_view.label ~= label or last_view.drawing ~= true or last_view.bg_color ~= bg_color then
    local safe_icon = icon:gsub('"', '\\"')
    local safe_label = label:gsub('"', '\\"')

    sbar.exec(
      'sketchybar --set media drawing=on icon="'
        .. safe_icon
        .. '" label="'
        .. safe_label
        .. '" background.color='
        .. bg_color
        .. ' label.background.color='
        .. bg_color
        .. ' --set media.spacer width=265'
    )

    last_view.icon = icon
    last_view.label = label
    last_view.drawing = true
    last_view.bg_color = bg_color
  end
end)
