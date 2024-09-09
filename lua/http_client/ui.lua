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
    local ok, parsed = pcall(vim.json.decode, body)
    if ok then
        return vim.json.encode(parsed, { indent = 2 })
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

function M.format_headers(headers)
    if type(headers) == "string" then
        local lines = vim.split(headers, "\n")
        local formatted = {}
        for _, line in ipairs(lines) do
            local header = line:gsub("^%d+:%s*", "")
            if header ~= "" then
                table.insert(formatted, header)
            end
        end
        return table.concat(formatted, "\n")
    elseif type(headers) == "table" then
        local formatted = {}
        for k, v in pairs(headers) do
            table.insert(formatted, string.format("%s: %s", k, v))
        end
        return table.concat(formatted, "\n")
    else
        return "No headers"
    end
end


function M.display_in_buffer(content, title)
    vim.schedule(function()
        -- Create a new buffer
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
        vim.api.nvim_buf_set_option(buf, 'swapfile', false)
        vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

        -- Set buffer name
        local buf_name = title .. ' ' .. os.time()
        pcall(vim.api.nvim_buf_set_name, buf, buf_name)

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
    M.display_in_buffer(prepared_response, "HTTP Response")
end

return M

