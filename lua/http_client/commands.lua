local M = {}
local environment = require('http_client.environment')
local file_utils = require('http_client.file_utils')
local http_client = require('http_client.http_client')
local parser = require('http_client.parser')
local ui = require('http_client.ui')
local dry_run = require('http_client.dry_run')

M.select_env_file = function()
    local files = file_utils.find_files('*.env.json')
    vim.ui.select(files, {
        prompt = 'Select environment file:',
    }, function(choice)
        if choice then
            environment.set_env_file(choice)
            print('Environment file set to: ' .. choice)
        end
    end)
end

M.set_env = function(env_name)
    local success = environment.set_env(env_name)
    if success then
        print('Environment set to: ' .. env_name)
    else
        print('Failed to set environment: ' .. env_name)
    end
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
    http_client.stop_request()
    print('HTTP request stopped')
end

M.set_verbose_mode = function(enabled)
    http_client.set_verbose_mode(enabled)
    print(string.format("Verbose mode %s", enabled and "enabled" or "disabled"))
end

M.dry_run = function()
    dry_run.display_dry_run(M)
end

return M

