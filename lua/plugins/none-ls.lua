return {
	{
		"stevearc/conform.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local conform = require("conform")
			conform.setup({
				formatters_by_ft = {
					lua = { "stylua" },
					javascript = { "prettier" },
					typescript = { "prettier" },
					javascriptreact = { "prettier" },
					typescriptreact = { "prettier" },
					css = { "prettier" },
					html = { "prettier" },
					json = { "prettier" },
					yaml = { "prettier" },
					markdown = { "prettier" },
					groovy = { "npm_groovy_lint" },
					-- Add other formatters as needed
				},
				formatters = {
					npm_groovy_lint = {
						command = "npm-groovy-lint",
						args = { "--format", "$FILENAME" },
						cwd = require("conform.util").root_file({ ".groovylintrc.json", ".groovylintrc.js" }),
					},
				},
				format_on_save = {
					timeout_ms = 5000, -- Increased timeout
					lsp_fallback = true,
				},
			})

			vim.keymap.set({ "n", "v" }, "<leader>gf", function()
				conform.format({
					lsp_fallback = true,
					async = false,
					timeout_ms = 5000, -- Increased timeout
				})
			end, { desc = "Format file or range (in visual mode)" })
		end,
	},
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lint = require("lint")
			lint.linters_by_ft = {
				javascript = { "eslint" },
				typescript = { "eslint" },
				javascriptreact = { "eslint" },
				typescriptreact = { "eslint" },
				groovy = { "npm_groovy_lint" },
				-- Add other linters as needed
			}

			lint.linters.npm_groovy_lint = {
				cmd = "npm-groovy-lint",
				args = { "--linter", "$FILENAME" },
				ignore_exitcode = true,
				parser = function(output, bufnr)
					local diagnostics = {}
					for line in output:gmatch("[^\r\n]+") do
						local severity, message, lnum, col = line:match("([^|]+)|([^|]+)|(%d+)|(%d+)")
						if severity and message and lnum and col then
							table.insert(diagnostics, {
								source = "npm-groovy-lint",
								lnum = tonumber(lnum) - 1,
								col = tonumber(col) - 1,
								end_lnum = tonumber(lnum) - 1,
								end_col = tonumber(col),
								severity = vim.diagnostic.severity[severity:upper()] or vim.diagnostic.severity.WARN,
								message = message:gsub("^%s*(.-)%s*$", "%1"),
								bufnr = bufnr,
							})
						end
					end
					return diagnostics
				end,
			}

			local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

			vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
				group = lint_augroup,
				callback = function()
					lint.try_lint()
				end,
			})

			vim.keymap.set("n", "<leader>gl", function()
				lint.try_lint()
			end, { desc = "Trigger linting for current file" })
		end,
	},
}
