local M = {}

local vvv = require('http_client.utils.verbose')
local parser = require('http_client.core.parser')
local environment = require('http_client.core.environment')
local http_client = require('http_client.core.http_client')


M.run_request = function()
    local verbose = vvv.get_verbose_mode()
    vvv.set_verbose_mode(verbose)

    local request = parser.get_request_under_cursor()
    if not request then
        print('\nNo valid HTTP request found under cursor')
        return
    end

    if verbose then
        print("Parsed request:", vim.inspect(request)) -- Debug output
    end

    local env = environment.get_current_env()
    local env_needed = environment.env_variables_needed(request)

    if env_needed and not next(env) then
        print(
            'Environment variables are needed but not set. Please select an environment file or set properties via response handler.'
        )
        return
    end

    request = parser.replace_placeholders(request, env)

    if verbose then
        print("Request after placeholder replacement:", vim.inspect(request)) -- Debug output
    end

    http_client.send_request(request)
end

M.stop_request = function()
    local current_request = http_client.get_current_request()
    if not current_request then
        print('\nNo active request to stop')
        return
    end

    local success, error = pcall(function()
        http_client.stop_request()
    end)

    if success then
        print('\nHTTP request stopped successfully')
    else
        print('\nError stopping HTTP request: ' .. tostring(error))
    end

    -- Cleanup
    http_client.clear_current_request()
end

M.run_all = function()
 local verbose = vvv.get_verbose_mode()
    vvv.set_verbose_mode(verbose)

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local requests = parser.parse_all_requests(lines)
    local results = {}
    local env = environment.get_current_env()

    for _, request in ipairs(requests) do
        local env_needed = environment.env_variables_needed(request)
        if env_needed and not next(env) then
            table.insert(results, string.format("SKIP: %s %s - Environment variables needed but not set", request.method, request.url))
        else
            request = parser.replace_placeholders(request, env)
            local response = http_client.send_request_sync(request)
            local result = string.format("%s: %s %s %s %s",
                response.status < 400 and "OK" or "ERR",
                request.method,
                request.url,
                request.http_version or "HTTP/1.1",
                response.status)
            table.insert(results, result)
        end
    end

    local ui = require('http_client.ui.display')
    ui.display_in_buffer(table.concat(results, "\n"), "HTTP Run All Results")
end

return M

