return {
	{ "tpope/vim-fugitive" },
	{
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup()

			vim.keymap.set("n", "<leader>gp", ":Gitsigns preview_hunk<CR>", {})
			vim.keymap.set("n", "<leader>gt", ":Gitsigns toggle_current_line_blame<CR>", {})
		end,
	},
}

--git config --global user.name "User"
--git config --global user.email "user@gmail.com"
--cat .git/config
--git config --list
--git config -h // выводит опции и короткое описание
--git show // выводит информацию по коммиту
--git reset HEAD .idea // убрать все файлы папки .idea
-- git commit - m, git add -a //  работает только для проиндексированных файлов
-- git config --global alias.commitall '!git add .; git commit' алиас для сохранения текущей директории
-- git rm -r src = rm -r src + git add src
-- git rm -r --cashed src // untracked dir src (отсутствует в index)
-- git mv index.html hello.html // переименовал файл index.html и добавил в рабочую директорию index
