return {
  ---@module 'avante'
  {
    'yetone/avante.nvim',
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
        provider = 'gemini',
        behaviour = { enable_cursor_planning_mode = true },
        aihubmix = { hide_in_model_selector = true },
        ['aihubmix-claude'] = { hide_in_model_selector = true },
        bedrock = { hide_in_model_selector = true },
        ['bedrock-claude-3.7-sonnet'] = { hide_in_model_selector = true },
        claude = { hide_in_model_selector = true },
        ['claude-haiku'] = { hide_in_model_selector = true },
        ['claude-opus'] = { hide_in_model_selector = true },
        cohere = { hide_in_model_selector = true },
        copilot = { display_name = 'OpenAI GPT 4o' },
        deepseek = { hide_in_model_selector = true },
        gemini = {
          api_key_name = 'GEMINI_API_KEY',
          model = 'gemini-2.5-pro-exp-03-25',
          temperature = 0.7,
          max_tokens = tokens(256),
          display_name = 'Gemini 2.5 Pro',
        },
        openai = { hide_in_model_selector = true },
        ['openai-gpt-4o-mini'] = { hide_in_model_selector = true },
        vertex = { hide_in_model_selector = true },
        vertex_claude = { hide_in_model_selector = true },
        vendors = {
          ['qwen-coder-14b'] = generate_vendor('qwen2.5-coder-14b-instruct-mlx', 'Qwen 2.5 Coder 14B Instruct'),
          ['qwen-coder-7b'] = generate_vendor('qwen2.5-coder-7b-instruct-mlx', 'Qwen 2.5 Coder 7B Instruct'),
          ['cogito-v1-preview-14b'] = generate_vendor('deepcogito-cogito-v1-preview-qwen-14b', 'Cogito V1 Preview Qwen 14B'),
          ['qwen-7b-1m'] = generate_vendor('qwen2.5-7b-instruct-1m', 'Qwen 2.5 7B Instruct 1M'),
          ['deepseek-r1'] = generate_vendor('deepseek-r1-distill-qwen-14b', 'Deepseek R1 Distill Qwen 14B'),
          ['deepcoder-14b'] = generate_vendor('deepcoder-14b-preview', 'Deepcoder 14B Preview'),
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
          ['gpt-4.1'] = {
            __inherited_from = 'copilot',
            model = 'gpt-4.1',
            temperature = 0.2,
            max_tokens = tokens(256),
            display_name = 'OpenAI GPT 4.1',
          },
          ['o4-mini'] = {
            __inherited_from = 'copilot',
            model = 'o4-mini',
            max_tokens = tokens(256),
            display_name = 'OpenAI O4 Mini',
          },
          ['gemini-2.0-flash'] = {
            __inherited_from = 'gemini',
            model = 'gemini-2.5-flash-preview-04-17',
            temperature = 0.2,
            max_tokens = tokens(256),
            display_name = 'Gemini 2.5 Flash Preview',
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
      return {}
    end,
  },
  {
    'milanglacier/minuet-ai.nvim',
    enabled = false,
    event = 'BufReadPre',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = function()
      local gemini_prompt = [[
You are the backend of an AI-powered code completion engine. Your task is to
provide code suggestions based on the user's input. The user's code will be
enclosed in markers:

- `<contextAfterCursor>`: Code context after the cursor
- `<cursorPosition>`: Current cursor location
- `<contextBeforeCursor>`: Code context before the cursor
]]

      local gemini_few_shots = {
        {
          role = 'user',
          content = [[
# language: python
<contextBeforeCursor>
def fibonacci(n):
    <cursorPosition>
<contextAfterCursor>

fib(5)]],
        },
        {
          role = 'assistant',
          content = [[
    '''
    Recursive Fibonacci implementation
    '''
    if n < 2:
        return n
    return fib(n - 1) + fib(n - 2)
<endCompletion>
    '''
    Iterative Fibonacci implementation
    '''
    a, b = 0, 1
    for _ in range(n):
        a, b = b, a + b
    return a
<endCompletion>
]],
        },
      }

      local gemini_chat_input_template =
        '{{ printf "{{{language}}}" }}\n{{ printf "{{{tab}}}" }}\n<contextBeforeCursor>\n{{ printf "{{{context_before_cursor}}}" }}<cursorPosition>\n<contextAfterCursor>\n{{ printf "{{{context_after_cursor}}}" }}'

      return {
        provider = 'gemini',
        request_timeout = 4,
        throttle = 2000,
        provider_options = {
          gemini = {
            api_key = 'GEMINI_API_KEY',
            model = 'gemini-2.0-flash',
            system = {
              prompt = gemini_prompt,
            },
            few_shots = gemini_few_shots,
            chat_input = {
              template = gemini_chat_input_template,
            },
            optional = {
              generationConfig = {
                maxOutputTokens = 256,
                topP = 0.9,
              },
              safetySettings = {
                {
                  category = 'HARM_CATEGORY_DANGEROUS_CONTENT',
                  threshold = 'BLOCK_NONE',
                },
                {
                  category = 'HARM_CATEGORY_HATE_SPEECH',
                  threshold = 'BLOCK_NONE',
                },
                {
                  category = 'HARM_CATEGORY_HARASSMENT',
                  threshold = 'BLOCK_NONE',
                },
                {
                  category = 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
                  threshold = 'BLOCK_NONE',
                },
              },
            },
          },
        },
        virtualtext = {
          auto_trigger_ft = { '*' },
          auto_trigger_ignore_ft = { 'AvanteInput', 'snacks_picker_input' },
          keymap = {
            accept = '<Tab>',
            accept_line = '<A-a>',
            accept_n_lines = '<A-z>',
            next = ']]',
            prev = '[[',
            dismiss = '<C-e>',
          },
          show_on_completion_menu = true,
        },
      }
    end,
  },
  {
    'zbirenbaum/copilot.lua',
    enabled = true,
    cmd = 'Copilot',
    build = ':Copilot auth',
    event = 'InsertEnter',
    opts = {
      suggestion = {
        enabled = false,
        auto_trigger = true,
        hide_during_completion = true,
        keymap = {
          accept = false,
          next = '<M-]>',
          prev = '<M-[>',
        },
      },
      panel = { enabled = false },
      filetypes = {
        yaml = true,
        markdown = true,
        help = true,
      },
    },
  },
  {
    'Exafunction/codeium.vim',
    enabled = false,
    lazy = true,
    event = 'InsertEnter',
    cmd = 'Codeium',
    build = ':Codeium Auth',
    init = function()
      vim.g.codeium_filetypes = {
        oil = false,
        TelescopePrompt = false,
        NeoTree = false,
        AvanteInput = false,
      }
    end,
    config = function()
      vim.g.codeium_disable_bindings = true
      vim.g.codeium_enabled = true
      vim.keymap.set('i', '<Tab>', function()
        return vim.fn['codeium#Accept']()
      end, { expr = true, silent = true, desc = 'Codeium Accept' })
      vim.keymap.set('i', ']]', function()
        return vim.fn['codeium#CycleCompletions'](1)
      end, { expr = true, silent = true, desc = 'Codeium Next Completion' })
      vim.keymap.set('i', '[[', function()
        return vim.fn['codeium#CycleCompletions'](-1)
      end, { expr = true, silent = true, desc = 'Codeium Previous Completion' })
      vim.keymap.set('i', '<C-x>', function()
        return vim.fn['codeium#Clear']()
      end, { expr = true, silent = true, desc = 'Codeium Clear' })
      vim.keymap.set('i', '<C-\\>', function()
        return vim.fn['codeium#Complete']()
      end, { expr = true, silent = true, desc = 'Codeium Trigger Completion' })
      vim.keymap.set('n', '<leader>cc', function()
        return vim.fn['codeium#Chat']()
      end, { desc = '  [C]hat with [C]odeium' })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
