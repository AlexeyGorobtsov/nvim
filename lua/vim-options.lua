-- Basic editor settings
vim.opt.expandtab = true -- Convert tabs to spaces
vim.opt.tabstop = 2 -- Number of spaces a tab counts for
vim.opt.softtabstop = 2 -- Number of spaces for a tab while editing
vim.opt.shiftwidth = 2 -- Number of spaces for each indentation level
vim.opt.modifiable = true -- Allow buffer to be modified
vim.opt.number = true -- Show line numbers
vim.opt.relativenumber = true -- Show relative line numbers for easier navigation
vim.opt.scrolloff = 8 -- Keep 8 lines visible above/below cursor when scrolling
vim.opt.smartindent = true -- Smart auto-indenting
vim.opt.syntax = "on" -- Enable syntax highlighting
vim.o.termguicolors = true -- Enable true color support

-- Set space as the leader key
vim.g.mapleader = " "

-- Clipboard settings
vim.opt.clipboard = "unnamedplus" -- Use system clipboard

-- Color scheme
-- vim.cmd("colorscheme desert")      -- Set color scheme to desert

-- Spell checking
vim.opt.spell = true -- Enable spell checking
vim.opt.spelllang = { "en_us", "ru_ru" } -- Set spell check languages to English and Russian

-- Keymaps for window navigation
vim.keymap.set("n", "<c-k>", ":wincmd k<CR>", { desc = "Move to window above" })
vim.keymap.set("n", "<c-j>", ":wincmd j<CR>", { desc = "Move to window below" })
vim.keymap.set("n", "<c-h>", ":wincmd h<CR>", { desc = "Move to window left" })
vim.keymap.set("n", "<c-l>", ":wincmd l<CR>", { desc = "Move to window right" })

-- Custom keymaps
vim.keymap.set("n", "<leader>h", ":nohlsearch<CR>", { desc = "Clear search highlighting" })
vim.keymap.set("n", "<leader>tn", ":tabnext<CR>", { desc = "Go to next tab" })
vim.keymap.set("n", "<leader>pv", ":Vex<CR>", { noremap = true, desc = "Open vertical explorer" })

-- Paste from yank register (register 0) instead of default register
-- This preserves what you've copied when you delete something and then paste
vim.keymap.set("n", "p", '"0p', { noremap = true, desc = "Paste from yank register (normal mode)" })
vim.keymap.set("n", "P", '"0P', { noremap = true, desc = "Paste before cursor from yank register (normal mode)" })
vim.keymap.set("v", "p", '"0p', { noremap = true, desc = "Paste from yank register (visual mode)" })
vim.keymap.set("v", "P", '"0P', { noremap = true, desc = "Paste before cursor from yank register (visual mode)" })
