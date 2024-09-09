local M = {}
local curl = require('plenary.curl')

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
            callback(response)
        end
    })
end

M.stop_request = function()
    if current_request then
        current_request:shutdown()
        current_request = nil
    end
end

return M

