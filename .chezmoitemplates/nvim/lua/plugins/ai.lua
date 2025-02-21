local function generate_vendor(model)
  return {
    __inherited_from = 'openai',
    api_key_name = '',
    endpoint = '{{- if eq .chezmoi.os "darwin" -}}127.0.0.1:5001/v1{{- else -}}{{- .MacAddress -}}:5001/v1{{- end -}}',
    temperature = 0,
    max_tokens = 8192,
    model = model,
  }
end

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
  ---@module 'avante'
  {
    'yetone/avante.nvim',
    event = { 'BufReadPost', 'BufWritePost', 'BufNewFile' },
    build = vim.fn.has 'win32' == 0 and 'make' or
        'pwsh.exe -NoProfile -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false',
    ---@type avante.Config
    opts = {
      provider = 'gemini',
      gemini = {
        api_key_name = 'GEMINI_API_KEY',
        model = 'gemini-2.0-pro-exp-02-05',
        -- model = 'gemini-2.0-flash-thinking-exp-01-21',
      },
      vendors = {
        ['qwen'] = generate_vendor('qwen2.5-coder-14b-instruct-mlx'),
        ['supernova'] = generate_vendor('supernova-medius'),
        ['deepseek'] = generate_vendor('deepseek-r1-distill-qwen-14b'),
      },
      file_selector = { provider = 'snacks' },
    },
    keys = function()
      local wk = require('which-key')
      wk.add({
        { '<leader>a', group = '[A]vante', mode = { 'n', 'x' }, icon = { icon = ' ', color = 'green' } },
      })
    end
  },
  {
    'milanglacier/minuet-ai.nvim',
    enabled = true,
    event = 'BufReadPre',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = {
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
    },
  },
  {
    'zbirenbaum/copilot.lua',
    enabled = false,
    cmd = 'Copilot',
    build = ':Copilot auth',
    event = 'InsertEnter',
    opts = {
      suggestion = {
        auto_trigger = true,
        keymap = {
          accept = '<Tab>',
          next = ']]',
          prev = '[[',
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
