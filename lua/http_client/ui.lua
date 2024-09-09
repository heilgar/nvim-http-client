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


local function display_in_buffer(content, title)
    vim.schedule(function()
        -- Create a new buffer
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
        vim.api.nvim_buf_set_option(buf, 'swapfile', false)
        vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

        -- Set buffer name
        vim.api.nvim_buf_set_name(buf, title)

        -- Set buffer content
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, '\n'))

        -- Open in a vertical split
        vim.cmd('vsplit')
        local win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(win, buf)

        -- Set buffer to readonly
        vim.api.nvim_buf_set_option(buf, 'modifiable', false)
        vim.api.nvim_buf_set_option(buf, 'readonly', true)

        -- Set buffer-local keymaps
        local opts = { noremap = true, silent = true }
        vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':close<CR>', opts)
        vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':close<CR>', opts)
    end)
end

function M.format_headers(headers)
    local formatted = {}
    for k, v in pairs(headers or {}) do
        table.insert(formatted, string.format("%s: %s", k, v))
    end
    return table.concat(formatted, "\n")
end

function M.prepare_response(response)
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
        M.format_headers(response.headers),
        content_type,
        formatted_body
    )

    return content
end

function M.display_response(prepared_response)
    display_in_buffer(prepared_response, "HTTP Response")
end

return M

