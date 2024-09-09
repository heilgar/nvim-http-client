local M = {}

local function detect_content_type(headers)
    local content_type = headers["content-type"] or headers["Content-Type"]
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
    -- This is a simple XML formatter.
    local formatted = body:gsub("><", ">\n<")
    local indent = 0
    formatted = formatted:gsub("([^>]*>)", function(tag)
        local result = string.rep("  ", indent) .. tag
        if tag:match("^</") then
            indent = indent - 1
        elseif tag:match("/>$") then
            -- Do nothing
        elseif not tag:match("^<!") then
            indent = indent + 1
        end
        return result
    end)
    return formatted
end

function M.display_response(response)
    vim.schedule(function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
        vim.api.nvim_buf_set_option(buf, 'swapfile', false)
        vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

        local lines = {}
        table.insert(lines, "Status: " .. response.status)
        table.insert(lines, "")
        table.insert(lines, "Headers:")
        for k, v in pairs(response.headers) do
            table.insert(lines, k .. ": " .. v)
        end
        table.insert(lines, "")
        table.insert(lines, "Body:")

        local content_type = detect_content_type(response.headers)
        local formatted_body = response.body

        if content_type == "json" then
            formatted_body = format_json(response.body)
            vim.api.nvim_buf_set_option(buf, 'filetype', 'json')
        elseif content_type == "xml" then
            formatted_body = format_xml(response.body)
            vim.api.nvim_buf_set_option(buf, 'filetype', 'xml')
        elseif content_type == "html" then
            vim.api.nvim_buf_set_option(buf, 'filetype', 'html')
        end

        for line in formatted_body:gmatch("[^\r\n]+") do
            table.insert(lines, line)
        end

        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

        -- Open in a new tab
        vim.cmd('tabnew')
        local win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(win, buf)

        -- Apply syntax highlighting
        vim.cmd('syntax on')
    end)
end

return M

