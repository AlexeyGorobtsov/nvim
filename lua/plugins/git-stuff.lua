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
