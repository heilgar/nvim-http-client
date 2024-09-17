local M = {}

local function escape_quotes(str)
    return str:gsub('"', '\\"')
end

M.generate_curl = function(request)
    local curl_parts = { "curl" }

    -- Add method
    table.insert(curl_parts, "-X " .. request.method)

    -- Add headers
    for key, value in pairs(request.headers or {}) do
        table.insert(curl_parts, '-H "' .. escape_quotes(key) .. ': ' .. escape_quotes(value) .. '"')
    end

    -- Add body if present
    if request.body then
        table.insert(curl_parts, "-d '" .. request.body .. "'")
    end

    -- Add URL
    table.insert(curl_parts, '"' .. escape_quotes(request.url) .. '"')

    return table.concat(curl_parts, " ")
end

return M

