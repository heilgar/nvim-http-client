local http_client = require('http_client')


vim.api.nvim_create_user_command('HttpEnvFile', function()
    http_client.commands.select_env_file()
end, {})


vim.api.nvim_create_user_command('HttpEnv', function()
    http_client.commands.select_env()
end, { nargs = 1 })


vim.api.nvim_create_user_command('HttpRun', function(opts)
    http_client.commands.run_request({ verbose = opts.bang })
end, { bang = true })


vim.api.nvim_create_user_command('HttpStop', function()
    http_client.commands.stop_request()
end, {})

vim.api.nvim_create_user_command('HttpVerbose', function()
    http_client.commands.toggle_verbose_mode()
end, {})

vim.api.nvim_create_user_command('HttpDryRun', function()
    http_client.commands.dry_run()
end, {})

