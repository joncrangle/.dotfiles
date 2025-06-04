return {
  ---@module 'avante'
  {
    'yetone/avante.nvim',
    enabled = true,
    event = { 'BufReadPost', 'BufWritePost', 'BufNewFile' },
    build = vim.fn.has 'win32' == 0 and 'make' or 'pwsh.exe -NoProfile -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false',
    init = function()
      local searxng_url = '{{- .TnasAddress -}}'
      vim.env.SEARXNG_API_URL = string.gsub(searxng_url, ':.*$', ':8090')
    end,
    opts = function()
      --- Returns the number times 1024
      ---@param num number
      ---@return number
      local function tokens(num)
        return num * 1024
      end

      --- Generate an Avante provider
      ---@param opts { model: string, name: string, temperature?: number, max_tokens?: number, port?: number, min_p?: number, top_p?: number, top_k?: number }
      ---@return AvanteProvider
      local function generate_provider(opts)
        local port = opts.port or 5001
        return {
          __inherited_from = 'openai',
          api_key_name = '',
          endpoint = string.format('{{- if eq .chezmoi.os "darwin" -}}127.0.0.1{{- else -}}{{- .MacAddress -}}{{- end -}}:%d/v1', port),
          model = opts.model,
          display_name = opts.name,
          extra_request_body = {
            temperature = opts.temperature or 0,
            max_tokens = opts.max_tokens or tokens(8),
            min_p = opts.min_p or 0,
            top_p = opts.top_p or 0.95,
            top_k = opts.top_k or -1,
          },
        }
      end

      ---@type avante.Config|{}
      return {
        provider = 'copilot',
        providers = {
          copilot = {
            model = 'gpt-4.1',
            extra_request_body = {
              temperature = 0.2,
              max_tokens = tokens(256),
              reasoning_effort = 'high',
            },
          },
          gemini = {
            model = 'gemini-2.5-flash-preview-04-17',
            extra_request_body = {
              temperature = 0.2,
              max_tokens = tokens(256),
            },
          },
          vertex = { hide_in_model_selector = true },
          vertex_claude = { hide_in_model_selector = true },
          ['qwen3-8b'] = generate_provider { model = 'qwen3-8b-mlx', name = 'Qwen 3 8B', temperature = 0.6 },
          ['qwen3-4b'] = generate_provider { model = 'qwen3-4b-mlx', name = 'Qwen 3 4B', temperature = 0.6 },
          ['gemma-3-12b-it-qat'] = generate_provider { model = 'gemma-3-12b-it-qat', name = 'Gemma 3 12B', temperature = 1 },
          ['gemma-3-4b-it-qat'] = generate_provider { model = 'gemma-3-4b-it-qat', name = 'Gemma 3 4B', temperature = 1 },
          ['omni-qwen3-4b'] = generate_provider { model = 'mlx-community/Qwen3-4B-4bit-DWQ-053125', temperature = 0.6, port = 10240 },
          ['omni-qwen3-8b'] = generate_provider { model = 'mlx-community/Qwen3-8B-4bit-DWQ-053125', temperature = 0.6, port = 10240 },
          ['omni-gemma3-4b'] = generate_provider { model = 'mlx-community/gemma-3-4b-it-4bit-DWQ', temperature = 1, port = 10240 },
        },
        selector = { provider = 'snacks' },
        web_search_engine = { provider = 'searxng' },
        windows = { sidebar_header = { rounded = false }, ask = { start_insert = false } },
        system_prompt = function()
          local hub = require('mcphub').get_hub_instance()
          if hub == nil then
            vim.notify('MCPHub not found', vim.log.levels.WARN, { title = 'Avante' })
            return nil
          end
          return hub:get_active_servers_prompt()
        end,
        custom_tools = function()
          return {
            require('mcphub.extensions.avante').mcp_tool(),
          }
        end,
        disabled_tools = {
          'list_files',
          'search_files',
          'read_file',
          'create_file',
          'rename_file',
          'delete_file',
          'create_dir',
          'rename_dir',
          'delete_dir',
          'bash',
        },
      }
    end,
    keys = function()
      local wk = require 'which-key'
      wk.add {
        { '<leader>a', group = '[A]vante', mode = { 'n', 'x' }, icon = { icon = ' ', color = 'green' } },
      }
    end,
  },
  {
    'ravitemer/mcphub.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    cmd = 'MCPHub',
    event = 'FileType AvanteInput',
    build = 'npm install -g mcp-hub@latest',
    opts = function()
      local lualine_ok, lualine = pcall(require, 'lualine')
      if lualine_ok then
        local config = lualine.get_config()
        local ext = require 'mcphub.extensions.lualine'
        if not vim.tbl_contains(config.sections.lualine_x, ext) then
          table.insert(config.sections.lualine_x, ext)
          lualine.setup(config)
        end
      end
      return { auto_approve = true }
    end,
  },
  {
    'copilotlsp-nvim/copilot-lsp',
    event = { 'BufReadPre', 'BufNewFile' },
    enabled = true,
    init = function()
      vim.g.copilot_nes_debounce = 500
      vim.lsp.enable 'copilot_ls'
      vim.keymap.set('n', '<tab>', function()
        -- Try to jump to the start of the suggestion edit.
        -- If already at the start, then apply the pending suggestion and jump to the end of the edit.
        local _ = require('copilot-lsp.nes').walk_cursor_start_edit()
          or (require('copilot-lsp.nes').apply_pending_nes() and require('copilot-lsp.nes').walk_cursor_end_edit())
      end)
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
