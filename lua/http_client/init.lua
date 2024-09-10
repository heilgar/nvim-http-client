local M = {}

M.config = {
    default_env_file = '.env.json',
    request_timeout = 30000, -- 30 seconds
    keybindings = {
        select_env_file = "<leader>he",
        set_env = "<leader>hs",
        run_request = "<leader>hr",
        stop_request = "<leader>hx",
        dry_run = "<leader>hd",
        toggle_verbose = "<leader>hv"
    },
}


local function setup_docs()
    if vim.fn.has("nvim-0.7") == 1 then
        vim.api.nvim_create_autocmd("BufWinEnter", {
            group = vim.api.nvim_create_augroup("http_client_docs", {}),
            pattern = "*/http_client/doc/*.txt",
            callback = function()
                vim.cmd("silent! helptags " .. vim.fn.expand("%:p:h"))
            end,
        })
    end
end

local function set_keybindings()
    local opts = { noremap = true, silent = true }

    vim.api.nvim_create_autocmd("FileType", {
        pattern = "http",
        callback = function()
            vim.keymap.set('n', M.config.keybindings.select_env_file, ':HttpEnvFile<CR>', opts)
            vim.keymap.set('n', M.config.keybindings.set_env, ':HttpEnv ', { noremap = true, buffer = true })
            vim.keymap.set('n', M.config.keybindings.run_request, ':HttpRun<CR>', opts)
            vim.keymap.set('n', M.config.keybindings.stop_request, ':HttpStop<CR>', opts)
            vim.keymap.set('n', M.config.keybindings.dry_run, ':HttpDryRun<CR>', opts)
            vim.keymap.set('n', M.config.keybindings.toggle_verbose, ':HttpVerbose<CR>', opts)
        end
    })
end

function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})

    -- Load all necessary modules
    M.environment = require('http_client.environment')
    M.file_utils = require('http_client.file_utils')
    M.http_client = require('http_client.http_client')
    M.parser = require('http_client.parser')
    M.ui = require('http_client.ui')
    M.dry_run = require('http_client.dry_run')
    M.commands = require('http_client.commands').setup(M.config)
    M.v = require('http_client.verbose')


    -- Set up commands
    vim.api.nvim_create_user_command('HttpEnvFile', function()
        M.commands.select_env_file()
    end, {
        desc = 'Select an environment file for HTTP requests.'
    })

    vim.api.nvim_create_user_command('HttpEnv', function()
        M.commands.select_env()
    end, {
        desc = 'Select an environment for HTTP request (requires one argument).',
    })

    vim.api.nvim_create_user_command('HttpRun', function()
        M.commands.run_request()
    end, {
        desc = 'Run the HTTP request under cursor. Use ! to enable verbose mode.',
    })

    vim.api.nvim_create_user_command('HttpVerbose', function()
        local current_state = M.v.get_verbose_mode()
        M.v.set_verbose_mode(not current_state)
        print(string.format("HTTP Client verbose mode %s", not current_state and "enabled" or "disabled"))
    end, {
        desc = 'Toggle verbose mode for HTTP request.'
    })

    vim.api.nvim_create_user_command('HttpStop', function()
        M.commands.stop_request()
    end, {
        desc = 'Stop the currently running HTTP request.'
    })

    vim.api.nvim_create_user_command('HttpDryRun', function()
        M.dry_run.display_dry_run(M)
    end, {
        desc = 'Perform a dry run of the HTTP request without sending it.'
    })



    setup_docs()
    set_keybindings()
end

return M

