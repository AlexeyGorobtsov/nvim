return {
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
      local capabilities = vim.lsp.protocol.make_client_capabilities()

      vim.lsp.config("*", {
        capabilities = capabilities,
      })

      -- TypeScript/JavaScript
      vim.lsp.config.ts_ls = {
        cmd = { "typescript-language-server", "--stdio" },
        filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
        root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
      }

      -- 🆕 ESLint LSP
      vim.lsp.config.eslint = {
        cmd = { "vscode-eslint-language-server", "--stdio" },
        filetypes = { 
          "javascript", 
          "javascriptreact", 
          "typescript", 
          "typescriptreact", 
          "vue", 
          "svelte" 
        },
        root_markers = { 
          "eslint.config.js",
          "eslint.config.mjs",
          "eslint.config.cjs",
          ".eslintrc.js", 
          ".eslintrc.json", 
          "package.json", 
          ".git" 
        },
        settings = {
          validate = "on",
          rulesCustomizations = {},
          run = "onType",
          nodePath = "",
          workingDirectory = { mode = "auto" },
        },
      }

      -- HTML
      vim.lsp.config.html = {
        cmd = { "vscode-html-language-server", "--stdio" },
        filetypes = { "html" },
        root_markers = { "package.json", ".git" },
      }

      -- CSS
      vim.lsp.config.cssls = {
        cmd = { "vscode-css-language-server", "--stdio" },
        filetypes = { "css", "scss", "less" },
        root_markers = { "package.json", ".git" },
      }

      -- JSON
      vim.lsp.config.jsonls = {
        cmd = { "vscode-json-language-server", "--stdio" },
        filetypes = { "json", "jsonc" },
        root_markers = { "package.json", ".git" },
      }

      -- Lua
      vim.lsp.config.lua_ls = {
        cmd = { "lua-language-server" },
        filetypes = { "lua" },
        root_markers = { ".luarc.json", ".luacheckrc", ".stylua.toml", ".git" },
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = {
              library = { vim.env.VIMRUNTIME },
              checkThirdParty = false,
            },
            telemetry = { enable = false },
          },
        },
      }

      -- Включить серверы
      vim.lsp.enable({
        "ts_ls",
        "eslint",
        "html",
        "cssls",
        "jsonls",
        "lua_ls",
      })

      -- Горячие клавиши при подключении LSP
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
        callback = function(args)
          local bufnr = args.buf
          local client = vim.lsp.get_client_by_id(args.data.client_id)

          local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
          end

          -- Навигация
          map("n", "gd", vim.lsp.buf.definition, "Go to Definition") -- Перейти к определению	Посмотреть код функции
          map("n", "gD", vim.lsp.buf.declaration, "Go to Declaration") -- Перейти к декларации	Найти .d.ts файл
          map("n", "gr", vim.lsp.buf.references, "References") -- Все использования	Перед удалением/рефакторингом
          map("n", "gi", vim.lsp.buf.implementation, "Implementation") -- Реализации интерфейса	ООП/TypeScript
          map("n", "K", vim.lsp.buf.hover, "Hover") -- Документация	Быстро посмотреть описание
          map("n", "<C-k>", vim.lsp.buf.signature_help, "Signature Help") -- Параметры функции	Во время вызова функции

          -- Действия
          map("n", "<leader>rn", vim.lsp.buf.rename, "Rename") -- Переименовать	Рефакторинг имени
          map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code Action") -- Быстрые исправления	Импорты/фиксы ошибок
          map("n", "<leader>f", function() -- Форматировать	Привести код в порядок
            vim.lsp.buf.format({ async = true })
          end, "Format")

          -- Inlay hints
          if client and client:supports_method("textDocument/inlayHint") then
            map("n", "<leader>th", function() -- Показать типы	TypeScript hints
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }))
            end, "Toggle Inlay Hints")
          end
        end,
      })

      -- Настройка диагностики с иконками
      vim.diagnostic.config({
        virtual_text = true,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.HINT] = "󰠠 ",
            [vim.diagnostic.severity.INFO] = " ",
          },
        },
        update_in_insert = false,
        underline = true,
        severity_sort = true,
        float = {
          border = "rounded",
          source = "always",
        },
      })

      -- Навигация по диагностике
      vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous Diagnostic" }) -- Пред./след. ошибка	Навигация по ошибкам
      vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next Diagnostic" }) -- Пред./след. ошибка	Навигация по ошибкам
      vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show Diagnostic" }) -- Показать ошибку	Детали ошибки
      vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostic List" }) -- Список ошибок	Обзор всех проблем
    end,
  },
}
