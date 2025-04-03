local M = {}
local curl = require('plenary.curl')
local vvv = require('http_client.utils.verbose')
local state = require('http_client.state')
local profiling = require('http_client.utils.profiling')

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

        if value == vim.NIL then
            return "null"
        elseif type(value) == "table" then
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

    local pr = {
        formatted_body = formatted_body,
        headers = response.headers or {},
        status = response.status or "N/A",
        content_type = content_type,
        response_handler = request.response_handler,
        request = {
            method = request.method,
            url = request.url,
            http_version = request.http_version or "N/A",
            test_name = request.test_name or "N/A",
        },
        request_id = request.request_id,
        timing_metrics = response.timing_metrics or {}
    }

    state.store_response(pr)

    return pr
end

local function display_response(pr)
    local ui = require('http_client.ui.display')
    local config = require('http_client.config')

    -- Format timing metrics if available
    local timing_str = ""
    local profiling_config = config.get('profiling')
    
    if profiling_config and profiling_config.enabled and profiling_config.show_in_response then
        if pr.timing_metrics and next(pr.timing_metrics) then
            timing_str = "\n# Timing:\n" .. profiling.format_metrics(pr.timing_metrics)
        end
    end

    local content = string.format([[
Response Information (%s):
---------------------
%s %s %s
# Status: %s

# Headers:
%s%s

# Body (%s):
%s
]],
        pr.request.test_name,
        pr.request.method,
        pr.request.url,
        pr.request.http_version,
        pr.status,
        format_headers(pr.headers),
        timing_str,
        pr.content_type,
        pr.formatted_body
    )

    ui.display_in_buffer(content, "HTTP Response")
end

local function handle_response(pr)
    local response_handler = require('http_client.core.response_handler')
    if pr.response_handler then
        local body
        if pr.content_type == "json" then
            local ok, decoded = pcall(vim.json.decode, pr.formatted_body)
            if ok then
                body = decoded
            else
                body = pr.formatted_body
            end
        else
            body = pr.formatted_body
        end

        response_handler.execute(pr.response_handler, {
            body = body,
            headers = pr.headers,
            status = pr.status
        })
    end
end

M.send_request = function(request)
    vvv.debug_print("Sending request...")
    vvv.debug_print(string.format("Method: %s, URL: %s, HTTP Version: %s", request.method, request.url,
        request.http_version))

    if current_request then
        vvv.debug_print("A request is already in progress")
        return
    end

    local config = require('http_client.config')
    local profiling_config = config.get('profiling')
    local profiling_enabled = profiling_config and profiling_config.enabled

    -- Generate request ID and add it to the request object
    request.request_id = profiling.generate_request_id()
    
    if profiling_enabled then
        profiling.start_metric(request.request_id, "total")
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

    if not request.url:match("^https?://") then
        request.url = "http://" .. request.url
    end

    local curl_options = {
        url = request.url,
        method = request.method,
        body = request.body,
        headers = request.headers,
        callback = function(response)
            if profiling_enabled then
                profiling.end_metric(request.request_id, "total")
            end
            
            vvv.debug_print("Response received")
            vvv.debug_print(string.format("Status: %s", response.status))
            vvv.debug_print("Response headers:")
            for k, v in pairs(response.headers) do
                vvv.debug_print(string.format("  %s: %s", k, v))
            end
            vvv.debug_print("Response body:")
            vvv.debug_print(response.body)

            current_request = nil
            
            if profiling_enabled then
                response.timing_metrics = profiling.get_metrics(request.request_id)
                response.timing_metrics.url = request.url
                profiling.clear_metrics(request.request_id)
            end

            vvv.debug_print("Calling ui.display_response")
            local pr = prepare_response(request, response)
            display_response(pr)
            handle_response(pr)
        end
    }

    -- Add event handlers only if profiling is enabled
    if profiling_enabled then
        curl_options.on_start = function()
            profiling.end_metric(request.request_id, "dns_resolution")
            profiling.start_metric(request.request_id, "connection")
        end
        
        curl_options.on_connect = function()
            profiling.end_metric(request.request_id, "connection")
            profiling.start_metric(request.request_id, "send_request")
        end
        
        curl_options.on_first_byte = function()
            profiling.end_metric(request.request_id, "send_request")
            
            -- Calculate server processing time
            local metrics = profiling.get_metrics(request.request_id)
            local start_time = 0
            
            if metrics.send_request and metrics.send_request.end_time then
                start_time = metrics.send_request.end_time
                
                local server_metrics = {}
                server_metrics.start_time = start_time
                server_metrics.end_time = vim.loop.hrtime()
                server_metrics.duration = (server_metrics.end_time - start_time) / 1000000
                
                metrics.server_processing = server_metrics
            end
            
            profiling.start_metric(request.request_id, "content_transfer")
        end
    end

    -- Handle different HTTP versions
    if request.http_version then
        if request.http_version == "HTTP/2" then
            curl_options.http_version = "HTTP/2"
        elseif request.http_version == "HTTP/2 (Prior Knowledge)" then
            curl_options.http_version = "HTTP/2"
        elseif request.http_version == "HTTP/1.1" then
            curl_options.http_version = "HTTP/1.1"
        else
            vvv.debug_print("Unknown HTTP version: " .. request.http_version)
        end
    end

    local ssl_config = require('http_client.core.environment').get_ssl_config()
    if ssl_config.verifyHostCertificate == false then
        curl_options.insecure = true
    end
    
    if profiling_enabled then
        profiling.start_metric(request.request_id, "dns_resolution")
    end

    current_request = curl.request(curl_options)

    if not current_request then
        vvv.debug_print("Failed to initiate request")
        if profiling_enabled then
            profiling.clear_metrics(request.request_id)
        end
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

M.send_request_sync = function(request)
    local config = require('http_client.config')
    local profiling_config = config.get('profiling')
    local profiling_enabled = profiling_config and profiling_config.enabled
    
    request.request_id = profiling.generate_request_id()
    
    if profiling_enabled then
        profiling.start_metric(request.request_id, "total")
    end
    
    local response = {}
    local curl_options = {
        url = request.url,
        method = request.method,
        body = request.body,
        headers = request.headers,
    }

    if request.http_version then
        if request.http_version == "HTTP/2" then
            curl_options.http_version = "HTTP/2"
        elseif request.http_version == "HTTP/2 (Prior Knowledge)" then
            curl_options.http_version = "HTTP/2"
        elseif request.http_version == "HTTP/1.1" then
            curl_options.http_version = "HTTP/1.1"
        end
    end

    local ssl_config = require('http_client.core.environment').get_ssl_config()
    if ssl_config.verifyHostCertificate == false then
        curl_options.insecure = true
    end

    response = curl.get(curl_options)
    
    if profiling_enabled then
        profiling.end_metric(request.request_id, "total")
        response.timing_metrics = profiling.get_metrics(request.request_id)
        response.timing_metrics.url = request.url
    end
    
    local pr = prepare_response(request, response)
    handle_response(pr)
    
    if profiling_enabled then
        profiling.clear_metrics(request.request_id)
    end

    return response
end

return M

