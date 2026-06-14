-- Basic editor settings
vim.opt.expandtab = true      -- Convert tabs to spaces
vim.opt.tabstop = 2           -- Number of spaces a tab counts for
vim.opt.softtabstop = 2       -- Number of spaces for a tab while editing
vim.opt.shiftwidth = 2        -- Number of spaces for each indentation level
vim.opt.modifiable = true     -- Allow buffer to be modified
vim.opt.number = true         -- Show line numbers
vim.opt.relativenumber = true -- Show relative line numbers for easier navigation
vim.opt.scrolloff = 8         -- Keep 8 lines visible above/below cursor when scrolling
vim.opt.smartindent = true    -- Smart auto-indenting
vim.opt.syntax = "on"         -- Enable syntax highlighting
vim.o.termguicolors = true    -- Enable true color support

-- Force UTF-8
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"

-- Set space as the leader key
vim.g.mapleader = " "

-- Clipboard settings
vim.opt.clipboard = "unnamedplus" -- Use system clipboard

-- Color scheme
vim.cmd('colorscheme catppuccin')


-- Spell checking
vim.opt.spell = true                     -- Enable spell checking
vim.opt.spelllang = { "en_us", "ru_ru" } -- Set spell check languages to English and Russian


-- Устанавливаем встроенную русскую раскладку (для Windows/Linux используйте russian-jcukenwin)
-- Для macOS можно использовать russian-jcukenmac
vim.opt.keymap = "russian-jcukenwin"

-- По умолчанию при старте включаем английский ввод
vim.opt.iminsert = 0
vim.opt.imsearch = 0
-- Настраиваем стандартную статусную строку без плагинов
-- %f - имя файла, %m - изменен ли, %= - разделитель, %k - имя раскладки, %l/%c - строка/колонка
vim.opt.statusline = "%f %m %= %k %l:%c"
vim.keymap.set("i", "jj", "<C-^>", { desc = "Toggle Russian layout" })

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

-- disable scroll
vim.o.mouse = ""

-- Подсветка синтаксиса
vim.cmd('syntax on')
vim.cmd('filetype plugin indent on')

-- Убираем жирный фон у границы и делаем его прозрачным
vim.api.nvim_set_hl(0, "FloatBorder", { link = "Normal" })
vim.opt.cursorline = true

vim.opt.foldmethod = "indent" -- Метод фолдинга: сворачивание по отступам
vim.opt.foldnestmax = 10      -- Максимальная глубина вложенности фолдов
vim.opt.foldenable = true     -- Включить фолдинг (возможность сворачивать код)
vim.opt.foldlevel = 15        -- Уровень фолдинга: блоки с отступом больше 15 будут свёрнуты
vim.opt.foldlevelstart = 15   -- Начальный уровень при открытии файла (блоки с отступом >2 будут свёрнуты)
-- Команды:
-- zc - закрыть фолд под курсором
-- zo - открыть фолд под курсором
-- za - переключить (toggle) фолд
-- zM - закрыть все фолды в файле
-- zR - открыть все фолды в файле
