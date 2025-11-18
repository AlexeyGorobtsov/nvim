local api = vim.api
local state = require('local-plugins.filemanager.state')
local ui = require('local-plugins.filemanager.ui')

local M = {}

-- Получить файл под курсором
function M.get_current_file()
  if not state.win or not api.nvim_win_is_valid(state.win) then
    return nil
  end

  local line = api.nvim_win_get_cursor(state.win)[1]

  if line == 1 or line == 2 then
    return nil
  end

  if line == 3 then
    return {
      name = '..',
      type = 'directory',
      path = vim.fn.fnamemodify(state.current_path, ':h')
    }
  end

  return state.files[line - 3]
end

-- Открыть файл/папку
function M.open_entry()
  local file = M.get_current_file()
  if not file then return end

  if file.type == 'directory' then
    state.current_path = file.path
    ui.render()
    api.nvim_win_set_cursor(state.win, { 3, 0 })
  else
    ui.close()
    vim.cmd('edit ' .. vim.fn.fnameescape(file.path))
  end
end

-- Вверх по дереву
function M.go_up()
  state.current_path = vim.fn.fnamemodify(state.current_path, ':h')
  ui.render()
  api.nvim_win_set_cursor(state.win, { 3, 0 })
end

-- LCD в текущую директорию
function M.lcd_to_current()
  local file = M.get_current_file()
  local target_path

  if file and file.type == 'directory' then
    target_path = file.path
  else
    target_path = state.current_path
  end

  -- Сделать lcd
  vim.cmd('lcd ' .. vim.fn.fnameescape(target_path))

  -- Обновить путь в FM и перерисовать
  state.current_path = target_path
  ui.render()
  api.nvim_win_set_cursor(state.win, { 3, 0 })

  vim.notify('📂 LCD: ' .. target_path, vim.log.levels.INFO)
end

return M
