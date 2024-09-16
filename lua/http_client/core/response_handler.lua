local M = {}
local environment = require('http_client.core.environment')
local vvv = require('http_client.utils.verbose')

local client = {
    global = {
        set = function(key, value)
            environment.set_global_variable(key, value)
            vvv.debug_print(string.format("Setting global variable: %s = %s", key, tostring(value)))
        end
    }
}

local function create_sandbox(response)
    return {
        client = client,
        response = {
            body = response.body or {},
            headers = response.headers or {},
            status = response.status or nil
        }
    }
end

M.execute = function(script, response)
    local sandbox = create_sandbox(response)
    local f, err = load(script, "response_handler", "t", sandbox)
    if f then
        local success, result = pcall(f)
        if not success then
            vvv.debug_print("Error executing response handler script: " .. tostring(result))
        end
    else
        vvv.debug_print("Error loading response handler script: " .. tostring(err))
    end
end

return M

