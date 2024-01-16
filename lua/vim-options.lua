vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.cmd("set modifiable") -- Enable modifiability
vim.g.mapleader = " "
-- Enable clipboard support
vim.cmd([[set clipboard=unnamedplus]])

-- Ensure that '+clipboard' is available (requires Neovim to be compiled with clipboard support)
if vim.fn.has("clipboard") == 1 then
	-- Use system clipboard for all operations
	vim.cmd([[set clipboard=unnamedplus]])
end

-- Navigate vim panes better
vim.keymap.set("n", "<c-k>", ":wincmd k<CR>")
vim.keymap.set("n", "<c-j>", ":wincmd j<CR>")
vim.keymap.set("n", "<c-h>", ":wincmd h<CR>")
vim.keymap.set("n", "<c-l>", ":wincmd l<CR>")

vim.keymap.set("n", "<leader>h", ":nohlsearch<CR>")
vim.keymap.set("n", "<leader>tn", ":tabnext<CR>")
vim.wo.number = true
