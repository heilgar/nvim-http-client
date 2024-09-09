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


    -- Set up commands
    vim.api.nvim_create_user_command('HttpEnvFile', function()
        M.commands.select_env_file()
    end, {})

    vim.api.nvim_create_user_command('HttpEnv', function()
        M.commands.select_env()
    end, { nargs = 1 })

    vim.api.nvim_create_user_command('HttpRun', function(cmd_opts)
        if cmd_opts.args == "-v" then
            M.http_client.set_verbose_mode(true)
        else
            M.http_client.set_verbose_mode(false)
        end
        M.commands.run_request()
    end, { nargs = '?' })

    vim.api.nvim_create_user_command('HttpVerbose', function(cmd_opts)
        if cmd_opts.args == "on" then
            M.http_client.set_verbose_mode(true)
            print("HTTP Client verbose mode enabled")
        elseif opts.args == "off" then
            M.http_client.set_verbose_mode(false)
            print("HTTP Client verbose mode disabled")
        else
            print("Usage: HttpVerbose on|off")
        end
    end, { nargs = 1, complete = function(_, _, _) return { "on", "off" } end })

    vim.api.nvim_create_user_command('HttpStop', function()
        M.commands.stop_request()
    end, {})

    vim.api.nvim_create_user_command('HttpDryRun', function()
        M.dry_run.display_dry_run(M)
    end, {})



    setup_docs()
    set_keybindings()
end

return M

