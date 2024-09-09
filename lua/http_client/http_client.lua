local M = {}
local curl = require('plenary.curl')
local ui = require('http_client.ui')

local current_request = nil
local verbose_mode = false

local function debug_print(message)
    if verbose_mode then
        vim.api.nvim_echo({ { string.format("[HTTP Client Debug] %s", message), "WarningMsg" } }, true, {})
    end
end

M.set_verbose_mode = function(enabled)
    verbose_mode = enabled
    debug_print(string.format("Verbose mode %s", enabled and "enabled" or "disabled"))
end

M.send_request = function(request, callback)
    debug_print("Sending request...")
    debug_print(string.format("Method: %s, URL: %s", request.method, request.url))

    if current_request then
        debug_print("A request is already in progress")
        return
    end

    debug_print("Headers:")
    for k, v in pairs(request.headers) do
        debug_print(string.format("  %s: %s", k, v))
    end

    if request.body then
        debug_print("Request body:")
        debug_print(request.body)
    else
        debug_print("No request body")
    end

    current_request = curl.request({
        url = request.url,
        method = request.method,
        body = request.body,
        headers = request.headers,
        callback = function(response)
            debug_print("Response received")
            debug_print(string.format("Status: %s", response.status))
            debug_print("Response headers:")
            for k, v in pairs(response.headers) do
                debug_print(string.format("  %s: %s", k, v))
            end

            current_request = nil
            local prepared_response = ui.prepare_response(response)
            ui.display_response(prepared_response)
            if callback then
                callback(response)
            end
        end
    })

    debug_print("Request sent, waiting for response...")
end

M.stop_request = function()
    if current_request then
        debug_print("Stopping current request")
        current_request:shutdown()
        current_request = nil
    else
        debug_print("No active request to stop")
    end
end

M.get_current_request = function()
    return current_request
end

return M

