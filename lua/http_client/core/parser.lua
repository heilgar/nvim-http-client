local M = {}

local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

local function extract_test_name(lines)
    if lines[1] and lines[1]:match("^###") then
        return lines[1]:match("^###%s*(.+)$") or ""
    end
    return ""
end

M.get_request_under_cursor = function()
    local current_line = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    local request_start, request_end
    local has_separators = false

    -- First pass: check if there are any ### separators
    for _, line in ipairs(lines) do
        if line:match("^###") then
            has_separators = true
            break
        end
    end

    if has_separators then
        -- Find the request that contains the cursor
        for i, line in ipairs(lines) do
            if line:match("^###") then
                if i <= current_line then
                    request_start = i
                else
                    request_end = i - 1
                    break
                end
            end
        end

        -- If no end found, it's the last request in the file
        if not request_end then
            request_end = #lines
        end

        -- If no start found, cursor is before any request
        if not request_start then
            return nil
        end
    else
        -- No separators, treat the whole file as one request
        request_start = 1
        request_end = #lines
    end

    local request_lines = vim.list_slice(lines, request_start, request_end)
    local test_name = extract_test_name(request_lines)

    -- Remove the ### line from request_lines if it exists
    if has_separators and request_lines[1] and request_lines[1]:match("^###") then
        table.remove(request_lines, 1)
    end

    -- If request_lines is empty after removing ###, it means cursor was on the ### line
    -- In this case, include the next request if available
    if #request_lines == 0 and request_end < #lines then
        request_end = request_end + 1
        while request_end < #lines and not lines[request_end + 1]:match("^###") do
            request_end = request_end + 1
        end
        request_lines = vim.list_slice(lines, request_start + 1, request_end)
    end

    -- If still empty, return nil
    if #request_lines == 0 then
        return nil
    end

    local request = M.parse_request(request_lines)
    request.test_name = test_name
    return request
end

M.parse_request = function(lines)
    local request = {
        method = nil,
        url = nil,
        headers = {},
        body = nil,
        http_version = nil
    }

    local stage = "start"
    local body_lines = {}

    for _, line in ipairs(lines) do
        line = trim(line)
        if line == "" then
            if stage == "headers" then
                stage = "body"
            end
        elseif stage == "start" then
            -- Updated regex to make HTTP version optional
            local method, url, version = line:match("^(%S+)%s+(.+)%s+(HTTP/%S+)$")
            if not method then
                -- If no HTTP version, try matching without it
                method, url = line:match("^(%S+)%s+(.+)$")
            end
            if method and url then
                request.method = method
                request.url = url
                request.http_version = version or "HTTP/1.1" -- Default to HTTP/1.1 if not specified
                stage = "headers"
            end
        elseif stage == "headers" then
            local key, value = line:match("^([^:]+):%s*(.+)$")
            if key and value then
                request.headers[trim(key)] = trim(value)
            end
        elseif stage == "body" then
            table.insert(body_lines, line)
        end
    end

    if #body_lines > 0 then
        request.body = table.concat(body_lines, "\n")
    end

    return request
end

M.replace_placeholders = function(request, env)
    local function replace(str)
        if str == nil then
            return nil
        end
        return (str:gsub("{{(.-)}}", function(var)
            return env[var] or "{{" .. var .. "}}"
        end))
    end

    if request.url then
        request.url = replace(request.url)
    end
    for k, v in pairs(request.headers) do
        request.headers[k] = replace(v)
    end
    if request.body then
        request.body = replace(request.body)
    end

    -- print("Request after placeholder replacement:", vim.inspect(request)) -- Debug output
    return request
end

return M

