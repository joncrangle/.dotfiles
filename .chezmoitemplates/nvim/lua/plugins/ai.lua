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
      --- Generate an Avante vendor configuration
      ---@param model string model name
      ---@param name? string display name
      ---@return AvanteProvider
      local function generate_vendor(model, name)
        return {
          __inherited_from = 'openai',
          api_key_name = '',
          endpoint = '{{- if eq .chezmoi.os "darwin" -}}127.0.0.1:5001/v1{{- else -}}{{- .MacAddress -}}:5001/v1{{- end -}}',
          model = model,
          display_name = name,
        }
      end

      ---@param num number
      ---@return number
      local function tokens(num)
        return num * 1024
      end

      ---@type avante.Config|{}
      return {
        provider = 'copilot',
        aihubmix = { hide_in_model_selector = true },
        ['aihubmix-claude'] = { hide_in_model_selector = true },
        bedrock = { hide_in_model_selector = true },
        ['bedrock-claude-3.7-sonnet'] = { hide_in_model_selector = true },
        claude = { hide_in_model_selector = true },
        ['claude-haiku'] = { hide_in_model_selector = true },
        ['claude-opus'] = { hide_in_model_selector = true },
        cohere = { hide_in_model_selector = true },
        copilot = {
          model = 'gpt-4.1',
          temperature = 0.2,
          max_tokens = tokens(256),
          display_name = 'OpenAI GPT 4.1',
        },
        deepseek = { hide_in_model_selector = true },
        gemini = {
          model = 'gemini-2.5-flash-preview-04-17',
          temperature = 0,
          max_tokens = tokens(256),
          display_name = 'Gemini 2.5 Flash Preview',
        },
        openai = { hide_in_model_selector = true },
        ['openai-gpt-4o-mini'] = { hide_in_model_selector = true },
        vertex = { hide_in_model_selector = true },
        vertex_claude = { hide_in_model_selector = true },
        vendors = {
          ['qwen3-30b-a3b'] = generate_vendor('qwen3-30b-a3b', 'Qwen 3 30B A3B'),
          ['qwen3-8b'] = generate_vendor('qwen3-8b-mlx', 'Qwen 3 8B'),
          ['qwen3-4b'] = generate_vendor('qwen3-4b-mlx', 'Qwen 3 4B'),
          ['gemma-3-12b-it-qat'] = generate_vendor('gemma-3-12b-it-qat', 'Gemma 3 12B'),
          ['gemma-3-4b-it-qat'] = generate_vendor('gemma-3-4b-it-qat', 'Gemma 3 4B'),
          ['claude-3.5-sonnet'] = {
            __inherited_from = 'copilot',
            model = 'claude-3.5-sonnet',
            temperature = 0.2,
            max_tokens = tokens(64),
            display_name = 'Claude 3.5 Sonnet',
          },
          ['claude-3.7-sonnet'] = {
            __inherited_from = 'copilot',
            model = 'claude-3.7-sonnet',
            temperature = 0.2,
            max_tokens = tokens(64),
            display_name = 'Claude 3.7 Sonnet',
          },
          ['claude-3.7-sonnet-thought'] = {
            __inherited_from = 'copilot',
            model = 'claude-3.7-sonnet-thought',
            temperature = 0.7,
            max_tokens = tokens(64),
            display_name = 'Claude 3.7 Sonnet Thought',
          },
          ['o4-mini'] = {
            __inherited_from = 'copilot',
            model = 'o4-mini',
            temperature = 0,
            max_tokens = tokens(256),
            display_name = 'OpenAI O4 Mini',
          },
          ['gemini-2.5-pro-preview'] = {
            __inherited_from = 'gemini',
            model = 'gemini-2.5-pro-preview-05-06',
            temperature = 0.7,
            max_tokens = tokens(256),
            display_name = 'Gemini 2.5 Pro Preview',
          },
        },
        file_selector = { provider = 'snacks' },
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
