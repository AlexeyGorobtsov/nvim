local uv = vim.loop
local M = {}

-- Получить список файлов
function M.get_files(path)
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

-- Создать файл
function M.create_file(path)
  local fd = uv.fs_open(path, "w", 420)
  if fd then
    uv.fs_close(fd)
    return true
  end
  return false
end

-- Создать папку
function M.create_dir(path)
  return uv.fs_mkdir(path, 493)
end

-- Копировать
function M.copy(src, dest)
  local cmd = string.format('cp -r %s %s',
    vim.fn.shellescape(src),
    vim.fn.shellescape(dest))
  return vim.fn.system(cmd)
end

-- Переместить
function M.move(src, dest)
  local cmd = string.format('mv %s %s',
    vim.fn.shellescape(src),
    vim.fn.shellescape(dest))
  return vim.fn.system(cmd)
end

-- Удалить
function M.delete(path)
  local cmd = string.format('rm -rf %s', vim.fn.shellescape(path))
  return vim.fn.system(cmd)
end

return M
