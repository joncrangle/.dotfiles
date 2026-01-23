return {
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      { 'mason-org/mason.nvim', cmd = 'Mason', opts = {} },
      { 'mason-org/mason-lspconfig.nvim', opts = {} },
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'b0o/schemastore.nvim', lazy = true, opts = nil },
      'SmiteshP/nvim-navic',
    },
    config = function()
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end
          map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })
          map('ge', '<cmd>lua vim.diagnostic.open_float()<CR>', 'Open [E]rror in Float')
          map('<leader>ci', function()
            vim.lsp.buf.code_action {
              apply = true,
              context = {
                only = { 'source.organizeImports' },
                diagnostics = {},
              },
            }
          end, 'LSP Organize [I]mports')

          if vim.bo.filetype == 'typescriptreact' then
            map('<leader>cI', function()
              vim.lsp.buf.code_action {
                apply = true,
                context = {
                  ---@diagnostic disable-next-line: assign-type-mismatch
                  only = { 'source.addMissingImports.ts' },
                  diagnostics = {},
                },
              }
            end, 'LSP Add Missing [I]mport')
          end
          -- The following two autocommands are used to highlight references of the
          -- word under your cursor when your cursor rests there for a little while.
          --    See `:help CursorHold` for information about when this is executed
          --
          -- When you move your cursor, the highlights will be cleared (the second autocommand).
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
            local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
            map('<leader>ti', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle [I]nlay Hints')
          end

          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentSymbol, event.buf) then
            require('nvim-navic').attach(client, event.buf)
          end
        end,
      })

      local servers = {
        astro = {},
        bacon_ls = {
          init_options = {
            updateOnSave = true,
            updateOnSaveWaitMillis = 1000,
            updateOnChange = false,
          },
        },
        bashls = {},
        biome = {},
        clangd = {},
        -- copilot = {},
        cssls = {},
        denols = {
          root_markers = { 'deno.json', 'deno.jsonc' },
          settings = {
            init_options = {
              enable = true,
              lint = true,
              unstable = true,
            },
          },
        },
        dockerls = {},
        docker_compose_language_service = {},
        gopls = {
          settings = {
            gopls = {
              gofumpt = true,
              codelenses = {
                gc_details = true,
                generate = true,
                regenerate_cgo = true,
                run_govulncheck = true,
                test = true,
                tidy = true,
                upgrade_dependency = true,
                version = true,
              },
              hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                compositeLiteralTypes = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
              },
              analyses = {
                fieldalignment = true,
                nilness = true,
                unusedparams = true,
                unusedwrite = true,
                useany = true,
              },
              usePlaceholders = true,
              completeUnimported = true,
              staticcheck = true,
              directoryFilters = { '-.git', '-.vscode', '-.idea', '-.vscode-test', '-node_modules' },
              semanticTokens = true,
            },
          },
        },
        harper_ls = {
          on_new_config = function(new_config)
            local ft = vim.bo[vim.api.nvim_get_current_buf()].filetype
            if vim.tbl_contains({ 'markdown', 'text', 'csv', 'typst' }, ft) then
              new_config.settings['harper-ls'].linters.SentenceCapitalization = true
              new_config.settings['harper-ls'].linters.SpellCheck = true
            end
          end,
          settings = {
            ['harper-ls'] = {
              linters = {
                SentenceCapitalization = false,
                SpellCheck = false,
              },
              dialect = 'Canadian',
            },
          },
        },
        html = {},
        jqls = {},
        jsonls = {
          -- Lazy-load schemastore when needed
          on_new_config = function(new_config)
            new_config.settings.json.schemas = new_config.settings.json.schemas or {}
            vim.list_extend(new_config.settings.json.schemas, require('schemastore').json.schemas())
          end,
          settings = {
            json = {
              format = {
                enable = true,
              },
              validate = { enable = true },
            },
          },
        },
        lua_ls = {
          settings = {
            Lua = {
              completion = {
                callSnippet = 'Replace',
              },
              hint = {
                enable = true,
              },
              codeLens = {
                enable = true,
              },
              doc = {
                privateName = { '^_' },
              },
            },
          },
        },
        marksman = {},
        mdx_analyzer = {},
        ruff = {},
        svelte = {},
        tailwindcss = {
          filetypes_exclude = { 'markdown' },
          filetypes_include = {},
        },
        templ = {},
        tinymist = {
          formatterMode = 'typstyle',
          exportPdf = 'never',
        },
        tsgo = {
          settings = {
            tsgo = {
              diagnostics = { translation = 'pretty' },
              enableMoveToFileCodeAction = true,
            },
            javascript = {
              updateImportsOnFileMove = { enabled = 'always' },
              suggest = { completeFunctionCalls = true },
              inlayHints = {
                enumMemberValues = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                parameterNames = { enabled = 'literals' },
                parameterTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                variableTypes = { enabled = false },
              },
            },
            typescript = {
              updateImportsOnFileMove = { enabled = 'always' },
              suggest = { completeFunctionCalls = true },
              inlayHints = {
                enumMemberValues = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                parameterNames = { enabled = 'literals' },
                parameterTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                variableTypes = { enabled = false },
              },
            },
          },
        },
        ty = {},
        yamlls = {
          -- Have to add this for yamlls to understand that we support line folding
          capabilities = {
            textDocument = {
              foldingRange = {
                dynamicRegistration = false,
                lineFoldingOnly = true,
              },
            },
          },
          -- lazy-load schemastore when needed
          on_new_config = function(new_config)
            new_config.settings.yaml.schemas = vim.tbl_deep_extend('force', new_config.settings.yaml.schemas or {}, require('schemastore').yaml.schemas())
          end,
          settings = {
            redhat = { telemetry = { enabled = false } },
            yaml = {
              keyOrdering = false,
              format = {
                enable = true,
              },
              validate = true,
              schemaStore = {
                -- Must disable built-in schemaStore support to use
                -- schemas from SchemaStore.nvim plugin
                enable = false,
                -- Avoid TypeError: Cannot read properties of undefined (reading 'length')
                url = '',
              },
            },
          },
        },
        zls = {},
      }

      local server_to_package = require('mason-lspconfig').get_mappings().lspconfig_to_package

      local function is_executable_available(server_name)
        -- First try the server name itself
        if vim.fn.executable(server_name) == 1 then
          return true
        end

        -- Then try the lspconfig default command
        local resolved = vim.lsp.config[server_name]
        if resolved and resolved.cmd then
          local binary
          local cmd = resolved.cmd

          if type(cmd) == 'table' then
            binary = cmd[1]
          elseif type(cmd) == 'function' then
            -- Safely execute the function to find the binary name
            local success, result = pcall(cmd)
            if success and type(result) == 'table' then
              binary = result[1]
            end
          end

          if binary and vim.fn.executable(binary) == 1 then
            return true
          end
        end

        -- Then try the mason package name
        local package_name = server_to_package[server_name]
        if package_name and vim.fn.executable(package_name) == 1 then
          return true
        end

        return false
      end

      local ensure_installed = {}

      -- Add servers that aren't available on system
      for server_name, _ in pairs(servers) do
        if not is_executable_available(server_name) then
          local package_name = server_to_package[server_name]
          if package_name then
            table.insert(ensure_installed, package_name)
          end
        end
      end

      local tools = {
        'codelldb',
        'js-debug-adapter',
        'powershell-editor-services',
      }

      -- Only install tools if not available on system
      for _, tool in ipairs(tools) do
        if vim.fn.executable(tool) == 0 then
          table.insert(ensure_installed, tool)
        end
      end

      -- Install missing tools/servers
      if #ensure_installed > 0 then
        require('mason-tool-installer').setup { ensure_installed = ensure_installed }
      end

      -- Check if the server should be enabled based on custom root markers
      local function is_enabled(server_opts)
        if not server_opts.root_markers or #server_opts.root_markers == 0 then
          return true
        end

        local cwd = vim.fn.getcwd()
        for _, marker in ipairs(server_opts.root_markers) do
          if vim.fn.filereadable(cwd .. '/' .. marker) == 1 then
            return true
          end
        end

        return false
      end

      for server, server_opts in pairs(servers) do
        vim.lsp.config(server, server_opts)
        if is_enabled(server_opts) == false then
          vim.lsp.enable(server, false)
        else
          vim.lsp.enable(server)
        end
      end
    end,
  },
  ---@module 'rustaceanvim'
  {
    'mrcjkb/rustaceanvim',
    ft = { 'rust' },
    ---@type rustaceanvim.Config
    opts = {
      server = {
        on_attach = function(_, bufnr)
          vim.keymap.set('n', '<leader>dr', function()
            vim.cmd.RustLsp 'debuggables'
          end, { desc = 'Rust Debuggables', buffer = bufnr })
        end,
        default_settings = {
          -- rust-analyzer language server configuration
          ['rust-analyzer'] = {
            cargo = {
              allFeatures = true,
              loadOutDirsFromCheck = true,
              buildScripts = {
                enable = true,
              },
            },
            -- Use bacon_ls instead of clippy
            checkOnSave = false,
            diagnostics = false,
            procMacro = {
              enable = true,
            },
            files = {
              exclude = {
                '.direnv',
                '.git',
                '.jj',
                '.github',
                '.gitlab',
                'bin',
                'node_modules',
                'target',
                'venv',
                '.venv',
              },
              -- Avoid Roots Scanned hanging, see https://github.com/rust-lang/rust-analyzer/issues/12613#issuecomment-2096386344
              watcher = 'client',
            },
          },
        },
      },
    },
    config = function(_, opts)
      vim.g.rustaceanvim = vim.tbl_deep_extend('keep', vim.g.rustaceanvim or {}, opts or {})
      if vim.fn.executable 'rust-analyzer' == 0 then
        vim.notify('rust-analyzer not found in PATH, please install it.\nhttps://rust-analyzer.github.io/', vim.log.levels.ERROR, { title = 'rustaceanvim' })
      end
    end,
  },
  ---@module 'crates'
  {
    'Saecki/crates.nvim',
    event = 'User CratesLoad',
    init = function()
      vim.api.nvim_create_autocmd('BufRead', {
        pattern = 'Cargo.toml',
        callback = function(ev)
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(ev.buf) and vim.bo[ev.buf].buflisted then
              vim.api.nvim_exec_autocmds('User', { pattern = 'CratesLoad' })
            end
          end)
        end,
      })
    end,
    ---@type crates.UserConfig
    opts = {
      lsp = {
        enabled = true,
        actions = true,
        completion = true,
        hover = true,
      },
    },
  },
  {
    'vuki656/package-info.nvim',
    event = { 'BufRead package.json' },
    opts = {
      highlights = {
        up_to_date = { fg = '#a6e3a1' },
        outdated = { fg = '#f9e2af' },
        invalid = { fg = '#f38ba8' },
      },
      package_manager = 'bun',
    },
  },
  { 'dmmulroy/ts-error-translator.nvim', ft = { 'typescript', 'typescriptreact', 'tsx' }, opts = {} },
  {
    'jmbuhr/otter.nvim',
    ft = 'markdown',
    opts = {},
    keys = function()
      vim.api.nvim_create_user_command('OtterToggle', function()
        local otter = require 'otter'
        if not vim.g.enable_otter then
          vim.g.enable_otter = true
          otter.activate()
          vim.notify('Otter enabled', vim.log.levels.INFO)
        else
          vim.g.enable_otter = false
          otter.deactivate()
          vim.notify('Otter disabled', vim.log.levels.INFO)
        end
      end, {
        desc = 'Toggle Otter',
      })
      return {
        { '<leader>to', '<cmd>OtterToggle<cr>', desc = '[T]oggle [O]tter' },
      }
    end,
  },
  {
    'SmiteshP/nvim-navic',
    event = 'LspAttach',
    opts = {
      depth_limit = 5,
      highlight = true,
    },
    config = function(_, opts)
      local navic = require 'nvim-navic'
      navic.setup(opts)

      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.server_capabilities.documentSymbolProvider then
            navic.attach(client, args.buf)
            -- Trigger initial update
            vim.opt_local.winbar = "%{%v:lua.require'nvim-navic'.get_location()%}"
          end
        end,
      })

      -- Fix navic text color (default is often too blue/colored)
      vim.api.nvim_set_hl(0, 'NavicText', { link = 'Normal' })
      vim.api.nvim_set_hl(0, 'NavicSeparator', { link = 'Comment' })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
