local M = {}
local curl = require('plenary.curl')
local vvv = require('http_client.verbose')

local current_request = nil

local function detect_content_type(headers)
    local content_type

    -- If headers are in key-value pair format
    for k, v in pairs(headers or {}) do
        -- Handle numeric keys if headers are returned as an array of strings
        if type(k) == "number" and type(v) == "string" then
            local header_key, header_value = v:match("^(.-):%s*(.*)")
            if header_key and header_key:lower() == "content-type" then
                content_type = header_value
                break
            end
        elseif type(k) == "string" and k:lower() == "content-type" then
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
    local ok, parsed = pcall(vim.json.decode, body)
    if not ok then
        return body -- Return original body if it's not valid JSON
    end

    local function encode_with_indent(value, indent)
        indent = indent or ""
        local newline = "\n" .. indent

        if type(value) == "table" then
            if vim.tbl_islist(value) then
                local items = {}
                for _, v in ipairs(value) do
                    table.insert(items, encode_with_indent(v, indent .. "  "))
                end
                return "[" .. newline .. "  " .. table.concat(items, "," .. newline .. "  ") .. newline .. "]"
            else
                local items = {}
                for k, v in pairs(value) do
                    table.insert(items, string.format('%q: %s', k, encode_with_indent(v, indent .. "  ")))
                end
                return "{" .. newline .. "  " .. table.concat(items, "," .. newline .. "  ") .. newline .. "}"
            end
        elseif type(value) == "string" then
            return string.format('%q', value)
        else
            return tostring(value)
        end
    end

    return encode_with_indent(parsed)
end

local function format_xml(body)
    local indent = 0
    local formatted = body:gsub("(<[^/!][^>]*>)", function(tag)
        local result = string.rep("  ", indent) .. tag
        if not tag:match("/>$") and not tag:match("</") then
            indent = indent + 1
        elseif tag:match("</") then
            indent = indent - 1
            result = string.rep("  ", indent) .. tag
        end
        return result
    end)
    return formatted
end

local function format_headers(headers)
    local formatted = {}
    for _, header in pairs(headers or {}) do
        -- Match header in the form of "Key: Value" and insert it directly
        local header_key, header_value = header:match("^(.-):%s*(.*)")
        if header_key and header_value then
            table.insert(formatted, string.format("%s: %s", header_key, header_value))
        end
    end
    return table.concat(formatted, "\n")
end

local function prepare_response(request, response)
    local content_type = detect_content_type(response.headers or {})
    local formatted_body = response.body or "No body"

    if content_type == "json" then
        formatted_body = format_json(formatted_body)
    elseif content_type == "xml" then
        formatted_body = format_xml(formatted_body)
    end

    local content = string.format([[
Response Information (%s):
---------------------
%s %s
# Status: %s

# Headers:
%s

# Body (%s):
%s
]],
        request.test_name or "N/A",
        request.method,
        request.url,
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

M.send_request = function(request)
    vvv.debug_print("Sending request...")
    vvv.debug_print(string.format("Method: %s, URL: %s", request.method, request.url))

    if current_request then
        vvv.debug_print("A request is already in progress")
        return
    end

    vvv.debug_print("Headers:")
    for k, v in pairs(request.headers) do
        vvv.debug_print(string.format("  %s: %s", k, v))
    end

    if request.body then
        vvv.debug_print("Request body:")
        vvv.debug_print(request.body)
    else
        vvv.debug_print("No request body")
    end

    current_request = curl.request({
        url = request.url,
        method = request.method,
        body = request.body,
        headers = request.headers,
        callback = function(response)
            vvv.debug_print("Response received")
            vvv.debug_print(string.format("Status: %s", response.status))
            vvv.debug_print("Response headers:")
            for k, v in pairs(response.headers) do
                vvv.debug_print(string.format("  %s: %s", k, v))
            end
            vvv.debug_print("Response body:")
            vvv.debug_print(response.body)

            current_request = nil

            vvv.debug_print("Calling ui.display_response")
            local pr = prepare_response(request, response)
            display_response(pr)
        end
    })

    if not current_request then
        vvv.debug_print("Failed to initiate request")
        return
    end

    vvv.debug_print("Request sent, waiting for response...")
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

