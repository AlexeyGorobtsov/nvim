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

vim.api.nvim_create_user_command('PrettierFormat', function()
  local file = vim.fn.expand('%:p')

  local root = vim.fs.find({
    '.prettierrc',
    '.prettierrc.json',
    '.prettierrc.js',
    '.prettierrc.cjs',
    '.prettierrc.mjs',
    '.prettierrc.yaml',
    '.prettierrc.yml',
    'prettier.config.js',
    'prettier.config.cjs',
    'prettier.config.mjs',
    'package.json',
  }, { upward = true, path = vim.fn.expand('%:p:h') })[1]

  local cwd = root and vim.fn.fnamemodify(root, ':h') or vim.fn.getcwd()

  vim.system(
    { 'prettier', '--write', file },
    { cwd = cwd },
    vim.schedule_wrap(function(out)
      if out.code == 0 then
        vim.cmd('checktime')
        vim.notify('Prettier: formatted ' .. vim.fn.fnamemodify(file, ':t'), vim.log.levels.INFO)
      else
        vim.notify(
          out.stderr ~= '' and out.stderr or out.stdout,
          vim.log.levels.ERROR
        )
      end
    end)
  )
end, {})

vim.keymap.set('n', '<leader>pf', ':PrettierFormat<CR>', { desc = 'Prettier format file' })
