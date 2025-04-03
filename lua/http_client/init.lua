local M = {}

M.config = require("http_client.config")

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
    if M.config.get("create_keybindings") then
        local opts = { noremap = true, silent = true }
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "http",
            callback = function()
                local keybindings = M.config.get("keybindings")

                vim.keymap.set("n", keybindings.select_env_file, ":HttpEnvFile<CR>", opts)
                vim.keymap.set(
                    "n",
                    keybindings.set_env,
                    ":HttpEnv<CR>",
                    { noremap = true, buffer = true }
                )
                vim.keymap.set("n", keybindings.run_request, ":HttpRun<CR>", opts)
                vim.keymap.set("n", keybindings.stop_request, ":HttpStop<CR>", opts)
                vim.keymap.set("n", keybindings.dry_run, ":HttpDryRun<CR>", opts)
                vim.keymap.set("n", keybindings.toggle_verbose, ":HttpVerbose<CR>", opts)
                vim.keymap.set("n", keybindings.copy_curl, ":HttpCopyCurl<CR>", opts)
                vim.keymap.set("n", keybindings.save_response, ":HttpSaveResponse<CR>", opts)
                vim.keymap.set("n", keybindings.toggle_profiling, ":HttpProfiling<CR>", opts)
            end,
        })
    end
end

M.setup = function(opts)
    M.config.setup(opts)

    -- Load all necessary modules
    M.environment = require("http_client.core.environment")
    M.file_utils = require("http_client.utils.file_utils")
    M.http_client = require("http_client.core.http_client")
    M.parser = require("http_client.core.parser")
    M.ui = require("http_client.ui.display")
    M.dry_run = require("http_client.ui.dry_run")
    M.v = require("http_client.utils.verbose")
    M.commands = require("http_client.commands")
    M.completion = require("http_client.completion")
    
    -- Initialize completion module
    M.completion.setup()

    -- Set up filetype detection
    vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
        pattern = {"*.http", "*.rest"},
        callback = function()
            vim.bo.filetype = "http"
        end
    })

    -- Set up commands
    vim.api.nvim_create_user_command("HttpEnvFile", function()
        M.commands.select_env.select_env_file(M.config.get())
    end, {
        desc = "Select an environment file for HTTP requests.",
    })

    vim.api.nvim_create_user_command("HttpEnv", function()
        M.commands.select_env.select_env()
    end, {
        desc = "Select an environment for HTTP request (requires one argument).",
    })

    vim.api.nvim_create_user_command("HttpRun", function()
        M.commands.request.run_request()
    end, {
        desc = "Run the HTTP request under cursor. Use ! to enable verbose mode.",
    })

    vim.api.nvim_create_user_command("HttpRunAll", function()
        M.commands.request.run_all()
    end, {
        desc = "Run all HTTP requests in the current file.",
    })

    vim.api.nvim_create_user_command("HttpStop", function()
        M.commands.request.stop_request()
    end, {
        desc = "Stop the currently running HTTP request.",
    })

    vim.api.nvim_create_user_command("HttpVerbose", function()
        local current_state = M.v.get_verbose_mode()
        M.v.set_verbose_mode(not current_state)
        print(string.format("HTTP Client verbose mode %s", not current_state and "enabled" or "disabled"))
    end, {
        desc = "Toggle verbose mode for HTTP request.",
    })

    vim.api.nvim_create_user_command("HttpProfiling", function()
        local profiling_enabled = M.config.get("profiling").enabled
        M.config.options.profiling.enabled = not profiling_enabled
        print(string.format("HTTP Client profiling %s", not profiling_enabled and "enabled" or "disabled"))
    end, {
        desc = "Toggle profiling for HTTP requests.",
    })

    vim.api.nvim_create_user_command("HttpDryRun", function()
        M.dry_run.display_dry_run(M)
    end, {
        desc = "Perform a dry run of the HTTP request without sending it.",
    })

    vim.api.nvim_create_user_command("HttpCopyCurl", function()
        M.commands.utils.copy_curl()
    end, {
        desc = "Copy curl command for the HTTP request under cursor.",
    })

    vim.api.nvim_create_user_command("HttpSaveResponse", function()
        M.commands.response.save_response()
    end, {
        desc = "Save the current HTTP response body to a file (formatted)",
    })

    setup_docs()
    set_keybindings()

    M.health = require("http_client.health")
    -- Register health check
    local health = vim.health or M.health
    if health.register then
        -- Register the health check with the new API
        health.register("http_client", M.health.check)
    else
        -- Fallback for older Neovim versions
        vim.api.nvim_create_autocmd("VimEnter", {
            callback = function()
                M.health.check()
            end,
        })
    end
end

return M

