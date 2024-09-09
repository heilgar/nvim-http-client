local M = {}
local environment = require('http_client.environment')
local file_utils = require('http_client.file_utils')
local http_client = require('http_client.http_client')
local parser = require('http_client.parser')
local ui = require('http_client.ui')
local dry_run = require('http_client.dry_run')

local config = {}

M.setup = function(cfg)
    config = cfg
    return M
end

M.select_env_file = function()
    local files = file_utils.find_files('*.env.json')
    local default_file = config.default_env_file or '.env.json'
    local default_index = nil

    -- Find the index of the default file
    for i, file in ipairs(files) do
        if file:match(default_file .. "$") then
            default_index = i
            break
        end
    end

    vim.ui.select(files, {
        prompt = 'Select environment file:',
        default = default_index
    }, function(choice)
        if choice then
            environment.set_env_file(choice)
            print('Environment file set to: ' .. choice)
            -- Automatically select environment after file selection
            M.select_env()
        end
    end)
end

M.select_env = function()
    if not environment.get_current_env_file() then
        print('No environment file selected. Please select an environment file first.')
        return
    end

    local env_data = file_utils.read_json_file(environment.get_current_env_file())
    if not env_data then
        print('Failed to read environment file')
        return
    end

    -- Set *default environment first
    local success = environment.set_env('*default')
    if success then
        print('Environment set to: *default')
    else
        print('Failed to set default environment')
        return
    end

    local env_names = {'*default'}
    for name, _ in pairs(env_data) do
        if name ~= '*default' then
            table.insert(env_names, name)
        end
    end

    vim.ui.select(env_names, {
        prompt = 'Select environment (current: *default):',
    }, function(choice)
        if choice and choice ~= '*default' then
            local success = environment.set_env(choice)
            if success then
                print('Environment set to: ' .. choice)
            else
                print('Failed to set environment: ' .. choice)
            end
        end
    end)
end

M.run_request = function(opts)
    local verbose = opts and opts.verbose or false
    http_client.set_verbose_mode(verbose)

    local request = parser.get_request_under_cursor(verbose)
    if not request then
        print('No valid HTTP request found under cursor')
        return
    end

    if verbose then
        print("Parsed request:", vim.inspect(request)) -- Debug output
    end

    local env = environment.get_current_env()
    request = parser.replace_placeholders(request, env, verbose)

    if verbose then
        print("Request after placeholder replacement:", vim.inspect(request)) -- Debug output
    end

    http_client.send_request(request, function(response)
        ui.display_response(response)
    end)
end

M.stop_request = function()
    local current_request = http_client.get_current_request()
    if not current_request then
        print('No active request to stop')
        return
    end

    local success, error = pcall(function()
        http_client.stop_request()
    end)

    if success then
        print('HTTP request stopped successfully')
    else
        print('Error stopping HTTP request: ' .. tostring(error))
    end

    -- Cleanup
    http_client.clear_current_request()
end

M.set_verbose_mode = function(enabled)
    http_client.set_verbose_mode(enabled)
    print(string.format("Verbose mode %s", enabled and "enabled" or "disabled"))
end

M.dry_run = function()
    dry_run.display_dry_run(M)
end

return M

