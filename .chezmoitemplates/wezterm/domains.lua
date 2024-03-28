---@diagnostic disable-next-line: unused-local
local wezterm = require 'wezterm'

local M = {}

function M.setup(config)
  config.ssh_domains = {
    {
      name = 'tnas',
      remote_address = '{{ .RemoteAddress }}',
      username = '{{ .RemoteUser }}',
      multiplexing = 'None',
    },
  }
end

return M
