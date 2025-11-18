return {
  dir = vim.fn.stdpath("config") .. "/lua/local-plugins/filemanager",
  name = "filemanager",
  lazy = false, -- Загружать сразу
  config = function()
    -- Создать команду
    vim.api.nvim_create_user_command('FM', function(opts)
      local fm = require('local-plugins.filemanager')
      fm.open(opts.args ~= '' and opts.args or nil)
    end, {
      nargs = '?',
      complete = 'dir',
      desc = 'Открыть файловый менеджер'
    })

    -- Опционально: маппинг
    vim.keymap.set('n', '<leader>e', '<cmd>FM<CR>', { desc = 'File Manager' })
  end,
}
