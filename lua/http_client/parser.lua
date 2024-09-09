local M = {}

M.get_request_under_cursor = function()
    local current_line = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    local start_line, end_line = current_line, current_line
    while start_line > 1 and lines[start_line - 1] ~= '###' do
        start_line = start_line - 1
    end
    while end_line < #lines and lines[end_line + 1] ~= '###' do
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

    local in_body = false
    for i, line in ipairs(lines) do
        if i == 1 then
            local method, url = line:match("(%S+)%s+(.+)")
            request.method = method
            request.url = url
        elseif line:match("^%s*$") then
            in_body = true
        elseif not in_body then
            local key, value = line:match("([^:]+):%s*(.+)")
            if key and value then
                request.headers[key] = value
            end
        else
            request.body = (request.body or "") .. line .. "\n"
        end
    end

    return request
end

M.replace_placeholders = function(request, env)
    local function replace(str)
        return (str:gsub("{{(.-)}}", function(var)
            return env[var] or "{{" .. var .. "}}"
        end))
    end

    request.url = replace(request.url)
    for k, v in pairs(request.headers) do
        request.headers[k] = replace(v)
    end
    if request.body then
        request.body = replace(request.body)
    end

    return request
end

return M

