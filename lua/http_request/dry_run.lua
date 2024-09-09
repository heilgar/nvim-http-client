local M = {}

function M.display_dry_run(http_request)
    local request = http_request.parser.get_request_under_cursor()
    if not request then
        print('No valid HTTP request found under cursor')
        return
    end

    local env = http_request.environment.get_current_env()
    request = http_request.parser.replace_placeholders(request, env)

    local dry_run_info = string.format([[
Dry Run Information:
--------------------
Method: %s
URL: %s

Headers:
%s

Body:
%s
]], request.method, request.url, M.format_headers(request.headers), request.body or "No body")

    -- Create a new split window
    vim.cmd('vsplit')
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_create_buf(false, true)

    -- Set buffer options
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'swapfile', false)
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_name(buf, 'HTTP Request Dry Run')

    -- Set the buffer to the window
    vim.api.nvim_win_set_buf(win, buf)

    -- Write the dry run info to the buffer
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(dry_run_info, '\n'))

    -- Set the buffer to readonly
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    vim.api.nvim_buf_set_option(buf, 'readonly', true)

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

