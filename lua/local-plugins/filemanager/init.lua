local state = require('local-plugins.filemanager.state')
local ui = require('local-plugins.filemanager.ui')
local keymaps = require('local-plugins.filemanager.keymaps')

local M = {}

function M.open(path)
  state.current_path = path or state.last_lcd_path or vim.fn.getcwd()

  ui.create_window()
  keymaps.setup(state.buf)
  ui.render()

  vim.api.nvim_win_set_cursor(state.win, { 3, 0 })
end

return M
