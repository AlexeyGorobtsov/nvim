return {
	{
		"williamboman/mason.nvim",
		lazy = false,
		config = function()
			require("mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		lazy = false,
		opts = {
			auto_install = true,
			-- Список серверов для автоустановки
			ensure_installed = {
				"ts_ls",
				"html",
				"lua_ls",
				"jsonls",
				"cssls",
				"pylsp",
				-- "pyright", -- альтернатива pylsp
				-- "ruff_lsp",
				"groovyls",
			},
		},
	},
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		config = function()
			-- Получаем capabilities от nvim-cmp
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			-- Глобальная конфигурация для всех серверов
			vim.lsp.config("*", {
				capabilities = capabilities,
			})

			-- TypeScript/JavaScript
			vim.lsp.config.ts_ls = {
				cmd = { "typescript-language-server", "--stdio" },
				filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
				root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
				settings = {
					typescript = {
						preferences = {
							importModuleSpecifierPreference = "relative",
						},
					},
					javascript = {
						preferences = {
							importModuleSpecifierPreference = "relative",
						},
					},
				},
			}

			-- HTML
			vim.lsp.config.html = {
				cmd = { "vscode-html-language-server", "--stdio" },
				filetypes = { "html" },
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

			-- JSON
			vim.lsp.config.jsonls = {
				cmd = { "vscode-json-language-server", "--stdio" },
				filetypes = { "json", "jsonc" },
				root_markers = { "package.json", ".git" },
			}

			-- CSS
			vim.lsp.config.cssls = {
				cmd = { "vscode-css-language-server", "--stdio" },
				filetypes = { "css", "scss", "less" },
				root_markers = { "package.json", ".git" },
			}

			-- Python LSP (pylsp)
			vim.lsp.config.pylsp = {
				cmd = { "pylsp" },
				filetypes = { "python" },
				root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
				settings = {
					pylsp = {
						plugins = {
							pycodestyle = {
								ignore = { "W391" },
								maxLineLength = 100,
							},
							pylint = { enabled = false },
							flake8 = { enabled = false },
						},
					},
				},
			}

			-- Alternative: Pyright (раскомментируйте если нужен вместо pylsp)
			-- vim.lsp.config.pyright = {
			-- 	cmd = { "pyright-langserver", "--stdio" },
			-- 	filetypes = { "python" },
			-- 	root_markers = { "pyproject.toml", "setup.py", ".git" },
			-- 	settings = {
			-- 		python = {
			-- 			analysis = {
			-- 				autoSearchPaths = true,
			-- 				diagnosticMode = "workspace",
			-- 				useLibraryCodeForTypes = true,
			-- 				typeCheckingMode = "basic",
			-- 			},
			-- 		},
			-- 	},
			-- }

			-- Ruff LSP (раскомментируйте если нужен)
			-- vim.lsp.config.ruff_lsp = {
			-- 	cmd = { "ruff-lsp" },
			-- 	filetypes = { "python" },
			-- 	root_markers = { "pyproject.toml", "ruff.toml", ".git" },
			-- }

			-- Groovy Language Server
			local mason_path = vim.fn.stdpath("data") .. "/mason/"
			local groovyls_jar = mason_path
				.. "packages/groovy-language-server/build/libs/groovy-language-server-all.jar"

			vim.lsp.config.groovyls = {
				cmd = { "java", "-jar", groovyls_jar },
				filetypes = { "groovy" },
				root_markers = { "*.gradle", "*.groovy", ".git" },
				settings = {
					groovy = {
						classpath = {},
						console = {},
						trace = {
							server = "verbose",
						},
					},
				},
			}

			-- Включаем все серверы
			vim.lsp.enable({
				"ts_ls",
				"html",
				"lua_ls",
				"jsonls",
				"cssls",
				"pylsp",
				-- "pyright", -- если используете вместо pylsp
				-- "ruff_lsp",
				"groovyls",
			})

			-- Глобальные горячие клавиши и настройки (для всех LSP)
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
				callback = function(args)
					local bufnr = args.buf
					local client = vim.lsp.get_client_by_id(args.data.client_id)

					-- Вспомогательная функция для маппинга
					local function map(mode, lhs, rhs, desc)
						vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, noremap = true, silent = true })
					end

					-- Базовые маппинги для всех LSP
					map("n", "gd", vim.lsp.buf.definition, "Go to Definition")
					map("n", "gD", vim.lsp.buf.declaration, "Go to Declaration")
					map("n", "gr", vim.lsp.buf.references, "References")
					map("n", "gi", vim.lsp.buf.implementation, "Go to Implementation")
					map("n", "K", vim.lsp.buf.hover, "Hover Documentation")
					map("n", "<C-k>", vim.lsp.buf.signature_help, "Signature Help")
					map("n", "<leader>D", vim.lsp.buf.type_definition, "Type Definition")
					map("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
					map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code Action")
					map("n", "<leader>f", function()
						vim.lsp.buf.format({ async = true })
					end, "Format")

					-- Специфичные действия для groovyls
					if client.name == "groovyls" then
						print("groovyls attached to buffer " .. bufnr)
					end

					-- Включить inlay hints если поддерживается
					if client.supports_method("textDocument/inlayHint") then
						map("n", "<leader>th", function()
							vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }))
						end, "Toggle Inlay Hints")
					end
				end,
			})

			-- Настройка диагностики
			vim.diagnostic.config({
				virtual_text = true,
				signs = true,
				update_in_insert = false,
				underline = true,
				severity_sort = true,
				float = {
					border = "rounded",
					source = "always",
					header = "",
					prefix = "",
				},
			})

			-- Иконки для диагностики в gutter
			local signs = {
				Error = " ",
				Warn = " ",
				Hint = "󰠠 ",
				Info = " ",
			}
			for type, icon in pairs(signs) do
				local hl = "DiagnosticSign" .. type
				vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
			end

			-- Кастомные команды для Groovy LSP
			vim.api.nvim_create_user_command("StopGroovyLSP", function()
				vim.cmd("LspStop groovyls")
			end, { desc = "Stop Groovy Language Server" })

			vim.api.nvim_create_user_command("RestartGroovyLSP", function()
				vim.cmd("LspStop groovyls")
				vim.defer_fn(function()
					vim.cmd("LspStart groovyls")
				end, 500)
			end, { desc = "Restart Groovy Language Server" })

			-- Дополнительные полезные маппинги для диагностики
			vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous Diagnostic" })
			vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next Diagnostic" })
			vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show Diagnostic" })
			vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostic List" })
		end,
	},
}
