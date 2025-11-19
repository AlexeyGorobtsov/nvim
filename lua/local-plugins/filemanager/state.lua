local M = {}

M.current_path = vim.fn.getcwd()
M.buf = nil
M.win = nil
M.files = {}
M.clipboard = nil
M.last_lcd_path = nil

function M.reset()
  M.current_path = vim.fn.getcwd()
  M.buf = nil
  M.win = nil
  M.files = {}
  M.clipboard = nil
  M.last_lcd_path = nil
end

function M.is_valid()
  return M.buf and vim.api.nvim_buf_is_valid(M.buf) and
         M.win and vim.api.nvim_win_is_valid(M.win)
end

return M
