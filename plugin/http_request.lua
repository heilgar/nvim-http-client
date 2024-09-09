local http_request = require('http_request')

vim.api.nvim_create_user_command('HttpEnvFile', function()
    http_request.commands.select_env_file()
end, {})

vim.api.nvim_create_user_command('HttpEnv', function(opts)
    http_request.commands.set_env(opts.args)
end, { nargs = 1 })

vim.api.nvim_create_user_command('HttpRun', function()
    http_request.commands.run_request()
end, {})

vim.api.nvim_create_user_command('HttpStop', function()
    http_request.commands.stop_request()
end, {})

