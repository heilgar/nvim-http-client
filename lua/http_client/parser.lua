local M = {}

local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

M.get_request_under_cursor = function()
    local current_line = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    local start_line, end_line = current_line, current_line
    while start_line > 1 and trim(lines[start_line - 1]) ~= '###' do
        start_line = start_line - 1
    end
    while end_line < #lines and trim(lines[end_line + 1]) ~= '###' do
        end_line = end_line + 1
    end

    local request_lines = vim.list_slice(lines, start_line, end_line)
    return M.parse_request(request_lines)
end

M.parse_request = function(lines)
    local request = {
        method = nil,
        url = nil,
        headers = {},
        body = nil
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
            local method, url = line:match("^(%S+)%s+(.+)$")
            if method and url then
                request.method = method
                request.url = url
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

    -- print("Parsed request:", vim.inspect(request)) -- Debug output
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

