local M = {}
local curl = require('plenary.curl')

local current_request = nil
_G.http_verbose_mode = false

local function debug_print(message)
    print(string.format("Debug print, verbose %s", tostring(_G.http_verbose_mode)))
    if _G.http_verbose_mode then
        print(string.format("[HTTP Client Debug] %s", message))
    end
end

local function detect_content_type(headers)
    local content_type
    for k, v in pairs(headers or {}) do
        if k:lower() == "content-type" then
            content_type = v
            break
        end
    end

    if content_type then
        if content_type:match("application/json") then
            return "json"
        elseif content_type:match("application/xml") or content_type:match("text/xml") then
            return "xml"
        elseif content_type:match("text/html") then
            return "html"
        end
    end
    return "text"
end

local function format_json(body)
    local ok, parsed = pcall(vim.fn.json_decode, body)
    if ok then
        return vim.fn.json_encode(parsed)
    end
    return body
end

local function format_xml(body)
    local formatted = body:gsub("><", ">\n<")
    local indent = 0
    formatted = formatted:gsub("([^>]*>)", function(tag)
        local result
        if tag:match("^</") then
            indent = indent - 1
        end
        result = string.rep("  ", indent) .. tag
        if not tag:match("/>$") and not tag:match("^</") then
            indent = indent + 1
        end
        return result
    end)
    return formatted
end

local function format_headers(headers)
    local formatted = {}
    for k, v in pairs(headers or {}) do
        table.insert(formatted, string.format("%s: %s", k, v))
    end
    return table.concat(formatted, "\n")
end

local function prepare_response(response)
    local content_type = detect_content_type(response.headers or {})
    local formatted_body = response.body or "No body"

    if content_type == "json" then
        formatted_body = format_json(formatted_body)
    elseif content_type == "xml" then
        formatted_body = format_xml(formatted_body)
    end

    local content = string.format([[
Response Information:
---------------------
Status: %s

Headers:
%s

Body (%s):
%s
]],
        response.status or "N/A",
        format_headers(response.headers),
        content_type,
        formatted_body
    )

    return content
end

local function display_response(prepared_response)
    local ui = require('http_client.ui')
    ui.display_in_buffer(prepared_response, "HTTP Response")
end



M.set_verbose_mode = function(enabled)
    http_verbose_mode = enabled
    debug_print(string.format("Verbose mode %s", enabled and "enabled" or "disabled"))
end

M.get_verbose_mode = function()
    return http_verbose_mode
end

M.send_request = function(request)
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
            debug_print("Response body:")
            debug_print(response.body)

            current_request = nil

            debug_print("Calling ui.display_response")
            local pr = prepare_response(response)
            display_response(pr)
        end
    })

    if not current_request then
        debug_print("Failed to initiate request")
        return
    end

    debug_print("Request sent, waiting for response...")
end

M.stop_request = function()
    if current_request then
        print("Stopping current request")
        current_request:shutdown()
        current_request = nil
    else
        print("No active request to stop")
    end
end

M.clear_current_request = function()
    current_request = nil
end

M.get_current_request = function()
    return current_request
end

return M

