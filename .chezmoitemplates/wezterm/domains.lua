---@diagnostic disable-next-line: unused-local
local wezterm = require 'wezterm'

local M = {}

function M.setup(config)
  config.ssh_domains = {
    {
      name = 'arch',
      remote_address = '{{ .ArchAddress }}',
      username = '{{ .ArchUser }}',
    },
    {
      name = 'mac',
      remote_address = '{{ .MacAddress }}',
      username = '{{ .MacUser }}',
    },
    {
      name = 'tnas',
      remote_address = '{{ .TnasAddress }}:9222',
      username = '{{ .TnasUser }}',
      multiplexing = 'None',
    },
  }
end

return M
