local api = vim.api
local state = require('local-plugins.filemanager.state')
local fs = require('local-plugins.filemanager.fs')

local M = {}

-- Отрисовка буфера
function M.render()
  if not state.buf or not api.nvim_buf_is_valid(state.buf) then
    return
  end

  api.nvim_buf_set_option(state.buf, 'modifiable', true)

  local lines = {}
  table.insert(lines, "📁 " .. state.current_path)
  table.insert(lines, "")
  table.insert(lines, "..  [родительская папка]")

  local files = fs.get_files(state.current_path)
  state.files = files

  for _, file in ipairs(files) do
    local icon = file.type == 'directory' and '📁' or '📄'
    table.insert(lines, icon .. ' ' .. file.name)
  end

  api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  api.nvim_buf_set_option(state.buf, 'modifiable', false)
  api.nvim_buf_set_option(state.buf, 'modified', false)
end

-- Создать окно
function M.create_window()
  state.buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_option(state.buf, 'bufhidden', 'wipe')
  api.nvim_buf_set_option(state.buf, 'buftype', 'nofile')
  api.nvim_buf_set_name(state.buf, 'FileManager')

  state.win = api.nvim_open_win(state.buf, true, {
    relative = 'editor',
    width = math.floor(vim.o.columns * 0.8),
    height = math.floor(vim.o.lines * 0.8),
    col = math.floor(vim.o.columns * 0.1),
    row = math.floor(vim.o.lines * 0.1),
    style = 'minimal',
    border = 'rounded'
  })

  M.setup_highlights()
end

-- Подсветка синтаксиса
function M.setup_highlights()
  vim.cmd([[
    syn match FMDir "📁.*"
    syn match FMFile "📄.*"
    syn match FMPath "^📁 /.*"
    hi def link FMDir Directory
    hi def link FMFile Normal
    hi def link FMPath Comment
  ]])
end

-- Закрыть окно
function M.close()
  if state.win and api.nvim_win_is_valid(state.win) then
    api.nvim_win_close(state.win, true)
  end
end

return M
