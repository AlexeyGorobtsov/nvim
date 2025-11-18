local M = {}
local api = vim.api
local uv = vim.loop

M.current_path = vim.fn.getcwd()
M.buf = nil
M.win = nil

-- Получить список файлов
local function get_files(path)
  local files = {}
  local handle = uv.fs_scandir(path)
  
  if not handle then
    return files
  end
  
  while true do
    local name, type = uv.fs_scandir_next(handle)
    if not name then break end
    
    table.insert(files, {
      name = name,
      type = type,
      path = path .. '/' .. name
    })
  end
  
  -- Сортировка: папки первыми
  table.sort(files, function(a, b)
    if a.type == b.type then
      return a.name < b.name
    end
    return a.type == 'directory'
  end)
  
  return files
end

-- Отрисовка буфера
local function render()
  if not M.buf or not api.nvim_buf_is_valid(M.buf) then
    return
  end
  
  api.nvim_buf_set_option(M.buf, 'modifiable', true)
  
  local lines = {}
  table.insert(lines, "📁 " .. M.current_path)
  table.insert(lines, "")
  table.insert(lines, "..  [родительская папка]")
  
  local files = get_files(M.current_path)
  M.files = files
  
  for _, file in ipairs(files) do
    local icon = file.type == 'directory' and '📁' or '📄'
    table.insert(lines, icon .. ' ' .. file.name)
  end
  
  api.nvim_buf_set_lines(M.buf, 0, -1, false, lines)
  api.nvim_buf_set_option(M.buf, 'modifiable', false)
  api.nvim_buf_set_option(M.buf, 'modified', false)
end

-- Получить файл под курсором
local function get_current_file()
  local line = api.nvim_win_get_cursor(M.win)[1]
  
  if line == 1 or line == 2 then
    return nil
  end
  
  if line == 3 then
    return {
      name = '..',
      type = 'directory',
      path = vim.fn.fnamemodify(M.current_path, ':h')
    }
  end
  
  return M.files[line - 3]
end

-- Открыть файл/папку
local function open_entry()
  local file = get_current_file()
  if not file then return end
  
  if file.type == 'directory' then
    M.current_path = file.path
    render()
    api.nvim_win_set_cursor(M.win, {3, 0})
  else
    -- Закрываем файловый менеджер
    if M.win and api.nvim_win_is_valid(M.win) then
      api.nvim_win_close(M.win, true)
    end
    -- Открываем файл
    vim.cmd('edit ' .. vim.fn.fnameescape(file.path))
  end
end

-- Копирование
local function copy_file()
  local file = get_current_file()
  if not file or file.name == '..' then return end
  
  M.clipboard = {action = 'copy', path = file.path, name = file.name}
  vim.notify("📋 Скопировано: " .. file.name, vim.log.levels.INFO)
end

-- Вырезание
local function cut_file()
  local file = get_current_file()
  if not file or file.name == '..' then return end
  
  M.clipboard = {action = 'cut', path = file.path, name = file.name}
  vim.notify("✂️  Вырезано: " .. file.name, vim.log.levels.INFO)
end

-- Вставка
local function paste_file()
  if not M.clipboard then
    vim.notify("Буфер обмена пуст", vim.log.levels.WARN)
    return
  end
  
  local dest = M.current_path .. '/' .. M.clipboard.name
  
  if M.clipboard.action == 'copy' then
    local cmd = string.format('cp -r %s %s',
      vim.fn.shellescape(M.clipboard.path),
      vim.fn.shellescape(dest))
    vim.fn.system(cmd)
  else
    local cmd = string.format('mv %s %s',
      vim.fn.shellescape(M.clipboard.path),
      vim.fn.shellescape(dest))
    vim.fn.system(cmd)
    M.clipboard = nil
  end
  
  render()
  vim.notify("✓ Вставлено", vim.log.levels.INFO)
end

-- Удаление
local function delete_file()
  local file = get_current_file()
  if not file or file.name == '..' then return end
  
  vim.ui.input({
    prompt = string.format("⚠️  Удалить '%s'? (yes/no): ", file.name),
  }, function(input)
    if input == "yes" or input == "y" then
      local cmd = string.format('rm -rf %s', vim.fn.shellescape(file.path))
      vim.fn.system(cmd)
      render()
      vim.notify("✓ Удалено: " .. file.name, vim.log.levels.INFO)
    end
  end)
end

-- Создать папку
local function create_dir()
  vim.ui.input({prompt = 'Имя папки: '}, function(name)
    if name and name ~= '' then
      local path = M.current_path .. '/' .. name
      uv.fs_mkdir(path, 493)
      render()
      vim.notify("✓ Создана папка: " .. name, vim.log.levels.INFO)
    end
  end)
end

-- Создать файл
local function create_file()
  vim.ui.input({prompt = 'Имя файла: '}, function(name)
    if name and name ~= '' then
      local path = M.current_path .. '/' .. name
      local fd = uv.fs_open(path, "w", 420)
      if fd then
        uv.fs_close(fd)
        render()
        vim.notify("✓ Создан файл: " .. name, vim.log.levels.INFO)
      end
    end
  end)
end

-- Переименовать
local function rename_file()
  local file = get_current_file()
  if not file or file.name == '..' then return end
  
  vim.ui.input({prompt = 'Новое имя: ', default = file.name}, function(name)
    if name and name ~= '' and name ~= file.name then
      local new_path = M.current_path .. '/' .. name
      local cmd = string.format('mv %s %s',
        vim.fn.shellescape(file.path),
        vim.fn.shellescape(new_path))
      vim.fn.system(cmd)
      render()
      vim.notify("✓ Переименовано", vim.log.levels.INFO)
    end
  end)
end

-- LCD в текущую директорию
local function lcd_to_current()
  local file = get_current_file()
  local target_path
  
  if file and file.type == 'directory' then
    target_path = file.path
  else
    target_path = M.current_path
  end
  
  if M.win and api.nvim_win_is_valid(M.win) then
    api.nvim_win_close(M.win, true)
  end
  
  vim.cmd('lcd ' .. vim.fn.fnameescape(target_path))
  vim.notify('📂 LCD: ' .. target_path, vim.log.levels.INFO)
end

-- Копирование названия файла/папки в буфер
local function yank_name()
  local names = {}
  
  -- Проверяем, есть ли визуальное выделение
  local mode = api.nvim_get_mode().mode
  
  if mode == 'v' or mode == 'V' then
    -- Визуальный режим - копируем несколько имён
    local start_line = vim.fn.line("'<")
    local end_line = vim.fn.line("'>")
    
    for line = start_line, end_line do
      if line == 3 then
        table.insert(names, '..')
      elseif line > 3 and M.files[line - 3] then
        table.insert(names, M.files[line - 3].name)
      end
    end
    
    -- Выходим из визуального режима
    local esc = api.nvim_replace_termcodes('<Esc>', true, false, true)
    api.nvim_feedkeys(esc, 'n', false)  --Корректный выход из visual mode
  else
    -- Нормальный режим - копируем одно имя
    local file = get_current_file()
    if file then
      table.insert(names, file.name)
    end
  end
  
  if #names > 0 then
    local result = table.concat(names, ' ')
    -- Копируем в системный буфер и в буфер vim
    vim.fn.setreg('+', result)
    vim.fn.setreg('"', result)
    
    local preview = #result > 50 and (result:sub(1, 47) .. '...') or result
    vim.notify("📋 Скопировано в буфер: " .. preview, vim.log.levels.INFO)
  end
end

-- Копирование полного пути
local function yank_path()
  local paths = {}
  local mode = api.nvim_get_mode().mode
  
  if mode == 'v' or mode == 'V' then
    local start_line = vim.fn.line("'<")
    local end_line = vim.fn.line("'>")
    
    for line = start_line, end_line do
      if line == 3 then
        table.insert(paths, vim.fn.fnamemodify(M.current_path, ':h'))
      elseif line > 3 and M.files[line - 3] then
        table.insert(paths, M.files[line - 3].path)
      end
    end
    
    vim.cmd('normal! ')
  else
    local file = get_current_file()
    if file then
      table.insert(paths, file.path)
    end
  end
  
  if #paths > 0 then
    local result = table.concat(paths, ' ')
    vim.fn.setreg('+', result)
    vim.fn.setreg('"', result)
    
    local preview = #result > 50 and (result:sub(1, 47) .. '...') or result
    vim.notify("📋 Скопирован путь: " .. preview, vim.log.levels.INFO)
  end
end

-- Главная функция открытия
function M.open(path)
  M.current_path = path or vim.fn.getcwd()
  
  M.buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_option(M.buf, 'bufhidden', 'wipe')
  api.nvim_buf_set_option(M.buf, 'buftype', 'nofile')
  api.nvim_buf_set_name(M.buf, 'FileManager')
  
  M.win = api.nvim_open_win(M.buf, true, {
    relative = 'editor',
    width = math.floor(vim.o.columns * 0.8),
    height = math.floor(vim.o.lines * 0.8),
    col = math.floor(vim.o.columns * 0.1),
    row = math.floor(vim.o.lines * 0.1),
    style = 'minimal',
    border = 'rounded'
  })
  
  local opts = {buffer = M.buf, silent = true}
  
  -- Навигация
  vim.keymap.set('n', '<CR>', open_entry, opts)
  vim.keymap.set('n', 'l', open_entry, opts)
  vim.keymap.set('n', 'h', function()
    M.current_path = vim.fn.fnamemodify(M.current_path, ':h')
    render()
    api.nvim_win_set_cursor(M.win, {3, 0})
  end, opts)
  
  -- Операции с файлами
  vim.keymap.set('n', 'yy', copy_file, opts)
  vim.keymap.set('n', 'dd', cut_file, opts)
  vim.keymap.set('n', 'p', paste_file, opts)
  vim.keymap.set('n', 'D', delete_file, opts)
  
  -- Копирование в буфер обмена
  vim.keymap.set({'n', 'v'}, 'yn', yank_name, opts)
  vim.keymap.set({'n', 'v'}, 'yp', yank_path, opts)
  
  -- Создание
  vim.keymap.set('n', 'a', create_file, opts)
  vim.keymap.set('n', 'A', create_dir, opts)
  
  -- Другое
  vim.keymap.set('n', 'r', rename_file, opts)
  vim.keymap.set('n', 'R', render, opts)
  vim.keymap.set('n', 'c', lcd_to_current, opts)
  vim.keymap.set('n', 'q', function()
    api.nvim_win_close(M.win, true)
  end, opts)
  vim.keymap.set('n', '<Esc>', function()
    api.nvim_win_close(M.win, true)
  end, opts)
  
  render()
  api.nvim_win_set_cursor(M.win, {3, 0})
  
  vim.cmd([[
    syn match FMDir "📁.*"
    syn match FMFile "📄.*"
    syn match FMPath "^📁 /.*" 
    hi def link FMDir Directory
    hi def link FMFile Normal
    hi def link FMPath Comment
  ]])
end

vim.api.nvim_create_user_command('FM', function(opts)
  M.open(opts.args ~= '' and opts.args or nil)
end, {
  nargs = '?',
  complete = 'dir',
  desc = 'Открыть файловый менеджер'
})

return M
