local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)
require("vim-options")
require("lazy").setup("plugins", {
  rocks = { enabled = false },  -- отключаем luarocks
})

vim.api.nvim_create_user_command("GroovyLint", function()
	vim.cmd("!npm-groovy-lint " .. vim.fn.expand("%"))
end, {})

-- 🆕 Улучшенная команда для ESLint fix
vim.api.nvim_create_user_command('EslintFix', function()
  -- Найти корневую директорию проекта
  local root = vim.fs.find({
    'eslint.config.js',
    'eslint.config.mjs',
    'eslint.config.cjs',
    '.eslintrc.js',
    '.eslintrc.json',
    'package.json',
    '.git'
  }, {
    upward = true,
    path = vim.fn.expand('%:p:h')
  })[1]
  
  if root then
    local root_dir = vim.fn.fnamemodify(root, ':h')
    local file = vim.fn.expand('%:p')
    
    -- Запустить eslint из корневой директории
    vim.cmd('!cd ' .. vim.fn.shellescape(root_dir) .. ' && npx eslint --fix ' .. vim.fn.shellescape(file))
    vim.cmd('e') -- Перезагрузить файл
  else
    vim.notify('ESLint config not found', vim.log.levels.ERROR)
  end
end, {})
-- Маппинг
vim.keymap.set('n', '<leader>ef', ':EslintFix<CR>', { desc = 'ESLint fix' })

-- Исключить из поиска файлов
vim.opt.wildignore:append({
  "*/node_modules/*",
  "*/dist/*",
  "*/build/*",
  "*/.git/*",
})

-- Настройка path для поиска (исключаем ненужные директории)
vim.opt.path:remove("/usr/include")
vim.opt.wildmenu = true
vim.opt.wildmode = "longest:full,full"

-- Для grep/vimgrep
vim.opt.grepprg = "rg --vimgrep --no-heading --smart-case"

