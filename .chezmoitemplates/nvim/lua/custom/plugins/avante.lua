return {
  {
    "yetone/avante.nvim",
    enabled = {{- if and (ne .chezmoi.os "darwin") (ne .chezmoi.os "linux") }} false{{- else }} true{{- end -}},
    event = "VeryLazy",
    build = "make",
    opts = {
      provider = 'qwen',
      vendors = {
        qwen = {
          ['local'] = true,
          endpoint = '{{- if eq .chezmoi.os "darwin" -}}127.0.0.1:11434/v1{{- else -}}{{- .MacAddress -}}:11434/v1{{- end -}}',
          model = 'qwen2.5-coder:7b-instruct',
          parse_curl_args = function(opts, code_opts)
            return {
              url = opts.endpoint .. "/chat/completions",
              headers = {
                ["Accept"] = "application/json",
                ["Content-Type"] = "application/json",
              },
              body = {
                model = opts.model,
                messages = require("avante.providers").copilot.parse_message(code_opts),
                max_tokens = 2048,
                stream = true,
              },
            }
          end,
          parse_response_data = function(data_stream, event_state, opts)
            require("avante.providers").openai.parse_response(data_stream, event_state, opts)
          end,
        },
        deepseek = {
          ['local'] = true,
          endpoint = '{{- if eq .chezmoi.os "darwin" -}}127.0.0.1:11434/v1{{- else -}}{{- .MacAddress -}}:11434/v1{{- end -}}',
          model = 'deepseek-coder-v2:16b-lite-instruct-q4_K_M',
          parse_curl_args = function(opts, code_opts)
            return {
              url = opts.endpoint .. "/chat/completions",
              headers = {
                ["Accept"] = "application/json",
                ["Content-Type"] = "application/json",
              },
              body = {
                model = opts.model,
                messages = require("avante.providers").copilot.parse_message(code_opts),
                max_tokens = 2048,
                stream = true,
              },
            }
          end,
          parse_response_data = function(data_stream, event_state, opts)
            require("avante.providers").openai.parse_response(data_stream, event_state, opts)
          end,
        },
      },
    }
  },
}
-- vim: ts=2 sts=2 sw=2 et
