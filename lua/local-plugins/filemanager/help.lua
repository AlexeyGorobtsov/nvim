local M = {}

-- Справка в виде текста
M.help_text = [[
╔══════════════════════════════════════════════════════════╗
║              FileManager - Горячие клавиши               ║
╚══════════════════════════════════════════════════════════╝

📂 Навигация:
  Enter, l    открыть файл/папку
  h           вверх по дереву каталогов
  q, Esc      закрыть файловый менеджер

📋 Операции с файлами:
  yy          копировать файл/папку
  dd          вырезать файл/папку
  p           вставить скопированное
  D           удалить (с подтверждением)

📝 Создание:
  a           создать новый файл
  A           создать новую папку
  r           переименовать файл/папку

📎 Копирование в системный буфер:
  yn          скопировать имя файла
  yp          скопировать полный путь
  (работает в визуальном режиме для нескольких файлов)

⚙️  Другое:
  R           обновить список файлов
  c           сделать lcd в текущую/выбранную папку
  ?           показать эту справку

💡 Подсказка: используйте визуальный режим (V) для 
   копирования имён нескольких файлов сразу
]]

-- Показать справку через notify
function M.show_notify()
  vim.notify(M.help_text, vim.log.levels.INFO, { 
    title = 'FileManager Help',
    timeout = 10000,  -- 10 секунд
  })
end

-- Показать справку в отдельном окне (альтернатива)
function M.show_window()
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Разбить текст на строки
  local lines = vim.split(M.help_text, '\n')
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Настройки буфера
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_name(buf, 'FileManager Help')
  
  -- Создать окно
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = 62,
    height = #lines + 2,
    col = math.floor((vim.o.columns - 62) / 2),
    row = math.floor((vim.o.lines - #lines) / 2),
    style = 'minimal',
    border = 'rounded',
    title = ' FileManager Help ',
    title_pos = 'center',
  })
  
  -- Закрыть по q или Esc
  vim.keymap.set('n', 'q', '<cmd>close<CR>', { buffer = buf, silent = true })
  vim.keymap.set('n', '<Esc>', '<cmd>close<CR>', { buffer = buf, silent = true })
  vim.keymap.set('n', '?', '<cmd>close<CR>', { buffer = buf, silent = true })
  
  -- Подсветка
  vim.cmd([[
    syn match HelpHeader "^╔.*╗$"
    syn match HelpHeader "^║.*║$"
    syn match HelpHeader "^╚.*╝$"
    syn match HelpSection "^📂.*:$"
    syn match HelpSection "^📋.*:$"
    syn match HelpSection "^📝.*:$"
    syn match HelpSection "^📎.*:$"
    syn match HelpSection "^⚙️.*:$"
    syn match HelpSection "^💡.*:$"
    syn match HelpKey "^\s\+\S\+\s*"
    
    hi def link HelpHeader Comment
    hi def link HelpSection Title
    hi def link HelpKey Keyword
  ]])
end

return M
