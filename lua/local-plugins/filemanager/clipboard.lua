local api = vim.api
local state = require('local-plugins.filemanager.state')
local fs = require('local-plugins.filemanager.fs')
local nav = require('local-plugins.filemanager.navigation')
local ui = require('local-plugins.filemanager.ui')

local M = {}

-- Копирование файла
function M.copy_file()
  local file = nav.get_current_file()
  if not file or file.name == '..' then return end

  state.clipboard = { action = 'copy', path = file.path, name = file.name }
  vim.notify("📋 Скопировано: " .. file.name, vim.log.levels.INFO)
end

-- Вырезание
function M.cut_file()
  local file = nav.get_current_file()
  if not file or file.name == '..' then return end

  state.clipboard = { action = 'cut', path = file.path, name = file.name }
  vim.notify("✂️  Вырезано: " .. file.name, vim.log.levels.INFO)
end

-- Вставка
function M.paste_file()
  if not state.clipboard then
    vim.notify("Буфер обмена пуст", vim.log.levels.WARN)
    return
  end

  local dest = state.current_path .. '/' .. state.clipboard.name

  if state.clipboard.action == 'copy' then
    fs.copy(state.clipboard.path, dest)
  else
    fs.move(state.clipboard.path, dest)
    state.clipboard = nil
  end

  ui.render()
  vim.notify("✓ Вставлено", vim.log.levels.INFO)
end

-- Копирование названия
function M.yank_name()
  local names = {}
  local mode = api.nvim_get_mode().mode

  if mode == 'v' or mode == 'V' then
    local start_line = vim.fn.line("'<")
    local end_line = vim.fn.line("'>")

    for line = start_line, end_line do
      if line == 3 then
        table.insert(names, '..')
      elseif line > 3 and state.files[line - 3] then
        table.insert(names, state.files[line - 3].name)
      end
    end

    local esc = api.nvim_replace_termcodes('<Esc>', true, false, true)
    api.nvim_feedkeys(esc, 'n', false)
  else
    local file = nav.get_current_file()
    if file then
      table.insert(names, file.name)
    end
  end

  if #names > 0 then
    local result = table.concat(names, ' ')
    vim.fn.setreg('+', result)
    vim.fn.setreg('"', result)

    local preview = #result > 50 and (result:sub(1, 47) .. '...') or result
    vim.notify("📋 Скопировано в буфер: " .. preview, vim.log.levels.INFO)
  end
end

-- Копирование пути
function M.yank_path()
  local paths = {}
  local mode = api.nvim_get_mode().mode

  if mode == 'v' or mode == 'V' then
    local start_line = vim.fn.line("'<")
    local end_line = vim.fn.line("'>")

    for line = start_line, end_line do
      if line == 3 then
        table.insert(paths, vim.fn.fnamemodify(state.current_path, ':h'))
      elseif line > 3 and state.files[line - 3] then
        table.insert(paths, state.files[line - 3].path)
      end
    end

    vim.cmd('normal! ')
  else
    local file = nav.get_current_file()
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

-- Удаление
function M.delete_file()
  local file = nav.get_current_file()
  if not file or file.name == '..' then return end

  vim.ui.input({
    prompt = string.format("⚠️  Удалить '%s'? (yes/no): ", file.name),
  }, function(input)
    if input == "yes" or input == "y" then
      fs.delete(file.path)
      ui.render()
      vim.notify("✓ Удалено: " .. file.name, vim.log.levels.INFO)
    end
  end)
end

return M
