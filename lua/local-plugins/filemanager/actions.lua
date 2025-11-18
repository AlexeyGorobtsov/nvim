local state = require('local-plugins.filemanager.state')
local fs = require('local-plugins.filemanager.fs')
local ui = require('local-plugins.filemanager.ui')

local M = {}

-- Создать папку
function M.create_dir()
  vim.ui.input({prompt = 'Имя папки: '}, function(name)
    if name and name ~= '' then
      local path = state.current_path .. '/' .. name
      fs.create_dir(path)
      ui.render()
      vim.notify("✓ Создана папка: " .. name, vim.log.levels.INFO)
    end
  end)
end

-- Создать файл
function M.create_file()
  vim.ui.input({prompt = 'Имя файла: '}, function(name)
    if name and name ~= '' then
      local path = state.current_path .. '/' .. name
      if fs.create_file(path) then
        ui.render()
        vim.notify("✓ Создан файл: " .. name, vim.log.levels.INFO)
      end
    end
  end)
end

-- Переименовать
function M.rename_file()
  local file = require('filemanager.navigation').get_current_file()
  if not file or file.name == '..' then return end
  
  vim.ui.input({prompt = 'Новое имя: ', default = file.name}, function(name)
    if name and name ~= '' and name ~= file.name then
      local new_path = state.current_path .. '/' .. name
      fs.move(file.path, new_path)
      ui.render()
      vim.notify("✓ Переименовано", vim.log.levels.INFO)
    end
  end)
end

return M
