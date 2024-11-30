local wezterm = require 'wezterm' --[[@as Wezterm]]
local podman = wezterm.target_triple:find 'darwin' and '/opt/homebrew/bin/podman' or 'podman'
local M = {}

local function podman_list()
  local podman_container_list = {}
  local success, stdout, _ =
      wezterm.run_child_process({ podman, 'container', 'ls', '--format', "{{ "{{.ID}}:{{.Names}}" }}" })
  if not success then
    return podman_container_list
  end
  for _, line in ipairs(wezterm.split_by_newlines(stdout)) do
    local id, name = line:match("(.-):(.+)")
    if id and name then
      podman_container_list[id] = name
    end
  end
  return podman_container_list
end

local function make_podman_label_func(id)
  return function(name)
    local _, stdout, _ =
        wezterm.run_child_process({ podman, 'inspect', '--format', "{{ "{{.State.Running}}" }}", id })
    local running = stdout == 'true\n'
    local color = running and 'Green' or 'Red'
    return wezterm.format({
      { Foreground = { AnsiColor = color } },
      { Text = 'podman container named ' .. name },
    })
  end
end

local function make_podman_fixup_func(id)
  return function(cmd)
    cmd.args = { 'sh' }
    local wrapped = {
      podman,
      'exec',
      '-it',
      id,
    }
    for _, arg in ipairs(cmd.args) do
      table.insert(wrapped, arg)
    end

    cmd.args = wrapped

    ---@diagnostic disable-next-line: undefined-field
    wezterm.log_info(wezterm.serde.json_encode(cmd))
    return cmd
  end
end

function M.apply_to_config(config)
  local exec_domains = {}
  for id, name in pairs(podman_list()) do
    table.insert(
      exec_domains,
      ---@diagnostic disable-next-line: param-type-mismatch
      wezterm.exec_domain('podman:' .. name, make_podman_fixup_func(id), make_podman_label_func(id))
    )
  end
  config.exec_domains = exec_domains
end

return M
