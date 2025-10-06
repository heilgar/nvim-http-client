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

local function create_headers_object(headers)
    local headers_table = {}

    -- Handle different header formats from plenary.curl
    if headers then
        for key, value in pairs(headers) do
            if type(key) == "number" and type(value) == "string" then
                -- Headers are in array format: ["Header-Name: value", ...]
                local header_key, header_value = value:match("^(.-):%s*(.*)")
                if header_key and header_value then
                    headers_table[header_key] = header_value
                end
            elseif type(key) == "string" then
                -- Headers are already in key-value format
                headers_table[key] = value
            end
        end
    end

    -- Create a headers object with valueOf method
    local headers_obj = {}

    -- Copy all header key-value pairs
    for key, value in pairs(headers_table) do
        headers_obj[key] = value
    end

    -- Add valueOf method
    headers_obj.valueOf = function(header_name)
        if not header_name then
            return nil
        end

        -- Try exact match first (case-sensitive)
        if headers_table[header_name] then
            return headers_table[header_name]
        end

        -- Try case-insensitive match
        for key, value in pairs(headers_table) do
            if string.lower(key) == string.lower(header_name) then
                return value
            end
        end

        return nil
    end

    return headers_obj
end

local function create_sandbox(response)
    return {
        client = client,
        response = {
            body = response.body or {},
            headers = create_headers_object(response.headers),
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

-- Expose create_sandbox for testing
M.create_sandbox = create_sandbox

return M
