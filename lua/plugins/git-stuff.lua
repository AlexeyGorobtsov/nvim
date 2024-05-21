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
-- git checkout -f master // флаг -f выбрасывает все изменения (удаляем незакомиченные изменения)
-- git checkout -f HEAD // отменить все изменения сделанные в ветке-- (удаляем незакомиченные изменения)
-- git stash // удаляет незакомиченные изменения и архивирует в git
-- git stash pop - вернуть незакомиченные изменения
-- git checkout -b fix // создаем и переключаемся на ветку
-- если ошибочно сделали коммит в мастере
-- 1) git branch fix // создаем новую ветку
-- 2) git checkout fix // переходим на ветку fix
-- 3) git branch -f master 54a4 переносим ветку мастер на коммит 54a4
-- git branch -f master fix // если нужно вернуть назад master на коммит fix
-- git checkout -B master 54a4 // если такая ветка есть он передвинет, а потом переключится 
-- detached HEAD // Отделенный HEAD
-- git checkout master 
-- detached head - отделенный head
-- git checkout master index.html - команда git checkout достает только указанный файл
-- git reset index.html сбрасывает index для данного конкретного файла
-- git log --oneline - выводит лог комитов
-- git show index.html @~:index.html смотрим изменения в файле на предыдущем коммите
-- git merge fix сливаем изменения из ветки fix в ветку мастер
-- cat .git/ORIG_HEAD - команда merge перед переносом ветки записывает старый идентификатор в ORIG_HEAD
-- git branch -f master ORIG_HEAD - возвращение мастера обратно до merge
-- git branch -d fix - удаление ветки fix
-- git reset --hard 2fad - передвигает текущую ветку на указанный коммит и обновляет рабочую 
-- директорию вместе с index, так чтобы они соответствовали состоянию проекту
-- git reset --hard - удаление не закомиченых изменений
-- git reset --soft @~ возвращает мастер на предыдущий коммит 
-- git commit -C ORIG_HEAD - C описание копируется из предыдущего коммита, с - откроется окно редактора
--
