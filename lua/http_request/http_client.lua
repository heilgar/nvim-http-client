local M = {}
local curl = require('plenary.curl')
local ui = require('http_request.ui')

local current_request = nil

M.send_request = function(request, callback)
    if current_request then
        print('A request is already in progress')
        return
    end

    current_request = curl.request({
        url = request.url,
        method = request.method,
        body = request.body,
        headers = request.headers,
        callback = function(response)
            current_request = nil
            local prepared_response = ui.prepare_response(response)
            ui.display_response(prepared_response)
            if callback then
                callback(response)
            end
        end
    })
end

M.stop_request = function()
    if current_request then
        current_request:shutdown()
        current_request = nil
    end
end

M.get_current_request = function ()
    return current_request
end

return M

