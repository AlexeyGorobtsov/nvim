local state = require('local-plugins.filemanager.state')
local fs = require('local-plugins.filemanager.fs')
local ui = require('local-plugins.filemanager.ui')

local M = {}

-- ══════════════════════════════════════════════════════════
-- Вспомогательные функции
-- ══════════════════════════════════════════════════════════

-- Создать все родительские папки для пути
local function ensure_parent_dirs(path)
  local parent = vim.fn.fnamemodify(path, ":h")
  if vim.fn.isdirectory(parent) == 0 then
    vim.fn.mkdir(parent, "p") -- "p" = создать все родительские папки
  end
end

-- Проверить, это файл или папка (папка заканчивается на /)
local function is_directory_path(path)
  return path:sub(-1) == "/"
end

-- ══════════════════════════════════════════════════════════
-- Универсальное создание файла/папки
-- ══════════════════════════════════════════════════════════

function M.create()
  vim.ui.input({ prompt = 'Создать (/ в конце = папка): ' }, function(input)
    if not input or input == '' then return end

    local full_path = state.current_path .. '/' .. input

    if is_directory_path(input) then
      -- Создать папку (убрать / в конце)
      local dir_path = full_path:sub(1, -2)
      vim.fn.mkdir(dir_path, "p")
      vim.notify("✓ Создана папка: " .. input, vim.log.levels.INFO)
    else
      -- Создать файл (и все родительские папки)
      ensure_parent_dirs(full_path)
      if fs.create_file(full_path) then
        vim.notify("✓ Создан файл: " .. input, vim.log.levels.INFO)
      end
    end

    ui.render()
  end)
end

-- ══════════════════════════════════════════════════════════
-- Отдельные функции
-- ══════════════════════════════════════════════════════════

-- Создать папку (с поддержкой вложенности)
function M.create_dir()
  vim.ui.input({ prompt = 'Имя папки: ' }, function(name)
    if not name or name == '' then return end

    local path = state.current_path .. '/' .. name
    vim.fn.mkdir(path, "p") -- "p" = создать все родительские папки
    ui.render()
    vim.notify("✓ Создана папка: " .. name, vim.log.levels.INFO)
  end)
end

-- Создать файл (с поддержкой вложенности)
function M.create_file()
  vim.ui.input({ prompt = 'Имя файла: ' }, function(name)
    if not name or name == '' then return end

    local path = state.current_path .. '/' .. name

    -- Создать родительские папки если нужно
    ensure_parent_dirs(path)

    if fs.create_file(path) then
      ui.render()
      vim.notify("✓ Создан файл: " .. name, vim.log.levels.INFO)
    end
  end)
end

-- Переименовать
function M.rename_file()
  local file = require('local-plugins.filemanager.navigation').get_current_file()
  if not file or file.name == '..' then return end

  vim.ui.input({ prompt = 'Новое имя: ', default = file.name }, function(name)
    if not name or name == '' or name == file.name then return end

    local new_path = state.current_path .. '/' .. name

    -- Если новое имя содержит /, создать родительские папки
    ensure_parent_dirs(new_path)

    fs.move(file.path, new_path)
    ui.render()
    vim.notify("✓ Переименовано", vim.log.levels.INFO)
  end)
end

return M
