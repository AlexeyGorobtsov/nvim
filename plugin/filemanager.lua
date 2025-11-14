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
    -- Используем системную команду cp
    local cmd = string.format('cp -r %s %s',
      vim.fn.shellescape(M.clipboard.path),
      vim.fn.shellescape(dest))
    vim.fn.system(cmd)
  else
    -- Используем mv
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
  
  local choice = vim.fn.confirm("Удалить " .. file.name .. "?", "&Да\n&Нет", 2)
  if choice == 1 then
    local cmd = string.format('rm -rf %s', vim.fn.shellescape(file.path))
    vim.fn.system(cmd)
    render()
    vim.notify("✓ Удалено: " .. file.name, vim.log.levels.INFO)
  end
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

-- Главная функция открытия
function M.open(path)
  M.current_path = path or vim.fn.getcwd()
  
  -- Создаём буфер
  M.buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_option(M.buf, 'bufhidden', 'wipe')
  api.nvim_buf_set_option(M.buf, 'buftype', 'nofile')
  api.nvim_buf_set_name(M.buf, 'FileManager')
  
  -- Создаём окно
  M.win = api.nvim_open_win(M.buf, true, {
    relative = 'editor',
    width = math.floor(vim.o.columns * 0.8),
    height = math.floor(vim.o.lines * 0.8),
    col = math.floor(vim.o.columns * 0.1),
    row = math.floor(vim.o.lines * 0.1),
    style = 'minimal',
    border = 'rounded'
  })
  
  -- Маппинги
  local opts = {buffer = M.buf, silent = true}
  vim.keymap.set('n', '<CR>', open_entry, opts)
  vim.keymap.set('n', 'l', open_entry, opts)
  vim.keymap.set('n', 'h', function()
    M.current_path = vim.fn.fnamemodify(M.current_path, ':h')
    render()
    api.nvim_win_set_cursor(M.win, {3, 0})
  end, opts)
  
  vim.keymap.set('n', 'yy', copy_file, opts)
  vim.keymap.set('n', 'dd', cut_file, opts)
  vim.keymap.set('n', 'p', paste_file, opts)
  vim.keymap.set('n', 'D', delete_file, opts)
  vim.keymap.set('n', 'a', create_file, opts)
  vim.keymap.set('n', 'A', create_dir, opts)
  vim.keymap.set('n', 'r', rename_file, opts)
  vim.keymap.set('n', 'R', render, opts)
  vim.keymap.set('n', 'q', function()
    api.nvim_win_close(M.win, true)
  end, opts)
  vim.keymap.set('n', '<Esc>', function()
    api.nvim_win_close(M.win, true)
  end, opts)
  
  render()
  api.nvim_win_set_cursor(M.win, {3, 0})
  
  -- Подсветка синтаксиса
  vim.cmd([[
    syn match FMDir "📁.*"
    syn match FMFile "📄.*"
    syn match FMPath "^📁 /.*" 
    hi def link FMDir Directory
    hi def link FMFile Normal
    hi def link FMPath Comment
  ]])
end

-- Команда
vim.api.nvim_create_user_command('FM', function(opts)
  M.open(opts.args ~= '' and opts.args or nil)
end, {
  nargs = '?',
  complete = 'dir',
  desc = 'Открыть файловый менеджер'
})

return M
