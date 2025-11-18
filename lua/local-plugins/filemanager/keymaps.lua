local M = {}

function M.setup(buf)
  local nav = require('local-plugins.filemanager.navigation')
  local clipboard = require('local-plugins.filemanager.clipboard')
  local actions = require('local-plugins.filemanager.actions')
  local ui = require('.local-plugins.filemanager.ui')
  local help = require('local-plugins.filemanager.help')

  local opts = { buffer = buf, silent = true }

  -- Навигация
  vim.keymap.set('n', '<CR>', nav.open_entry, opts)
  vim.keymap.set('n', 'l', nav.open_entry, opts)
  vim.keymap.set('n', 'h', nav.go_up, opts)

  -- Операции с файлами
  vim.keymap.set('n', 'yy', clipboard.copy_file, opts)
  vim.keymap.set('n', 'dd', clipboard.cut_file, opts)
  vim.keymap.set('n', 'p', clipboard.paste_file, opts)
  vim.keymap.set('n', 'D', clipboard.delete_file, opts)

  -- Копирование в буфер обмена
  vim.keymap.set({ 'n', 'v' }, 'yn', clipboard.yank_name, opts)
  vim.keymap.set({ 'n', 'v' }, 'yp', clipboard.yank_path, opts)

  -- Создание
  vim.keymap.set('n', 'a', actions.create_file, opts)
  vim.keymap.set('n', 'A', actions.create_dir, opts)

  -- Другое
  vim.keymap.set('n', 'r', actions.rename_file, opts)
  vim.keymap.set('n', 'R', ui.render, opts)
  vim.keymap.set('n', 'c', nav.lcd_to_current, opts)
  vim.keymap.set('n', 'q', ui.close, opts)
  vim.keymap.set('n', '<Esc>', ui.close, opts)

  vim.keymap.set('n', '?', help.show_window, opts)
end

return M
