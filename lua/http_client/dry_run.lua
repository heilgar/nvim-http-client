local M = {}

local function find_buffer_by_name(name)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_get_name(buf) == name then
            return buf
        end
    end
    return nil
end


function M.display_dry_run(http_client)
    local request = http_client.parser.get_request_under_cursor()
    if not request then
        print('No valid HTTP request found under cursor')
        return
    end

    local env = http_client.environment.get_current_env()
    request = http_client.parser.replace_placeholders(request, env)

    local env_file = http_client.environment.get_current_env_file() or "Not set"
    local env_info = vim.inspect(env or {})
    local current_request = vim.inspect(http_client.http_client.get_current_request() or {})

    local dry_run_info = string.format([[
Dry Run Information:
--------------------
Method: %s
URL: %s

Headers:
%s

Body:
%s

Environment Information:
------------------------
Current env file: %s

Current env:
%s

Current running request:
%s

Request under cursor:
%s
]],
        request.method,
        request.url,
        M.format_headers(request.headers),
        request.body or "No body",
        env_file,
        env_info,
        current_request,
        vim.inspect(request)
    )

    local buf_name = "HTTP Request Dry Run"
    local buf = find_buffer_by_name(buf_name)

    if buf then
        -- Buffer exists, switch to it and update content
        vim.api.nvim_set_current_buf(buf)
    else
        -- Create a new buffer
        vim.cmd('vsplit')
        local win = vim.api.nvim_get_current_win()
        buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_win_set_buf(win, buf)
        vim.api.nvim_buf_set_name(buf, buf_name)
    end

    -- Set buffer options
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'swapfile', false)
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

    -- Clear the buffer and write the dry run info
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(dry_run_info, '\n'))
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)

    -- Set buffer-local keymaps
    local opts = { noremap = true, silent = true }
    vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':close<CR>', opts)
    vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':close<CR>', opts)
end

function M.format_headers(headers)
    local formatted = {}
    for k, v in pairs(headers) do
        table.insert(formatted, k .. ": " .. v)
    end
    return table.concat(formatted, "\n")
end

return M

