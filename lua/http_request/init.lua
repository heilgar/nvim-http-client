local M = {}

M.config = {
    default_env_file = '.env.json',
    request_timeout = 30000, -- 30 seconds
    keybindings = {
        select_env_file = "<leader>he",
        set_env = "<leader>hs",
        run_request = "<leader>hr",
        stop_request = "<leader>hx",
    },
}


local function set_keybindings()
    local opts = { noremap = true, silent = true }

    vim.keymap.set('n', M.config.keybindings.select_env_file, ':HttpEnvFile<CR>', opts)
    vim.keymap.set('n', M.config.keybindings.set_env, ':HttpEnv ', { noremap = true })
    vim.keymap.set('n', M.config.keybindings.run_request, ':HttpRun<CR>', opts)
    vim.keymap.set('n', M.config.keybindings.stop_request, ':HttpStop<CR>', opts)
end

function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})

    -- Load all necessary modules
    M.commands = require('http_request.commands')
    M.environment = require('http_request.environment')
    M.file_utils = require('http_request.file_utils')
    M.http_client = require('http_request.http_client')
    M.parser = require('http_request.parser')
    M.ui = require('http_request.ui')

    -- Set up commands
    vim.api.nvim_create_user_command('HttpEnvFile', function()
        M.commands.select_env_file()
    end, {})

    vim.api.nvim_create_user_command('HttpEnv', function(params)
        M.commands.set_env(params.args)
    end, { nargs = 1 })

    vim.api.nvim_create_user_command('HttpRun', function()
        M.commands.run_request()
    end, {})

    vim.api.nvim_create_user_command('HttpStop', function()
        M.commands.stop_request()
    end, {})

    -- Set up keybindings
    set_keybindings()
end

return M

