return {
  dir = vim.fn.stdpath("config") .. "/lua/local-plugins/filemanager",
  name = "filemanager",
  lazy = false,
  config = function()
    local fm = require('local-plugins.filemanager')

    -- Команда FM - открывает в CWD или указанной директории
    vim.api.nvim_create_user_command('FM', function(opts)
      fm.open(opts.args ~= '' and opts.args or nil)
    end, {
      nargs = '?',
      complete = 'dir',
      desc = 'Открыть файловый менеджер'
    })

    -- Команда FMHere - открывает в директории текущего файла
    vim.api.nvim_create_user_command('FMHere', function()
      local current_file = vim.fn.expand('%:p')
      local current_dir = vim.fn.fnamemodify(current_file, ':h')

      -- Если файл не сохранен, используем CWD
      if current_file == '' then
        current_dir = vim.fn.getcwd()
      end

      fm.open(current_dir)
    end, {
      desc = 'Открыть файловый менеджер в директории текущего файла'
    })

    -- Маппинги
    vim.keymap.set('n', '<C-n>', '<cmd>FM<CR>', {
      desc = 'Toggle File Explorer'
    })

    vim.keymap.set('n', '<C-S-n>', '<cmd>FMHere<CR>', {
      desc = 'Toggle File Explorer (Current File)'
    })
  end,
}
