vim.api.nvim_create_user_command('GroovyLint', function()
  vim.cmd("!npm-groovy-lint " .. vim.fn.expand("%"))
end, {})

vim.api.nvim_create_user_command('EslintFix', function()
  local root = vim.fs.find({
    'eslint.config.js',
    'eslint.config.mjs',
    'eslint.config.cjs',
    '.eslintrc.js',
    '.eslintrc.json',
  }, { upward = true, path = vim.fn.expand('%:p:h') })[1]

  if not root then
    root = vim.fs.find({ 'package.json' }, {
      upward = true,
      path = vim.fn.expand('%:p:h')
    })[1]
  end

  if not root then
    vim.notify('ESLint config not found', vim.log.levels.ERROR)
    return
  end

  local root_dir = vim.fn.fnamemodify(root, ':h')
  local file = vim.fn.expand('%:p')

  vim.system(
    { 'npx', 'eslint', '--fix', file },
    { cwd = root_dir },
    vim.schedule_wrap(function(out)
      if out.code == 0 then
        vim.cmd('checktime')
      else
        vim.notify(
          out.stderr ~= '' and out.stderr or out.stdout,
          vim.log.levels.ERROR
        )
      end
    end)
  )
end, {})

vim.keymap.set('n', '<leader>ef', ':EslintFix<CR>', { desc = 'ESLint fix' })
