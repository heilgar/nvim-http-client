local M = {}

function M.display_debug_info(http_client)
    local env_file = http_client.environment.get_current_env_file() or "Not set"
    local env = vim.inspect(http_client.environment.get_current_env() or {})
    local current_request = vim.inspect(http_client.http_client.get_current_request() or {})

    local request_under_cursor = vim.inspect(http_client.parser.get_request_under_cursor() or {})

    local debug_info = string.format([[
Debug Information:
-----------------
Current env file: %s

Current env:
%s

Current running request:
%s

Request under cursor:
%s
]], env_file, env, current_request, request_under_cursor)

    -- Create a new split window
    vim.cmd('vsplit')
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_create_buf(false, true)

    -- Set buffer options
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'swapfile', false)
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_name(buf, 'HTTP Request Debug Info')

    -- Set the buffer to the window
    vim.api.nvim_win_set_buf(win, buf)

    -- Write the debug info to the buffer
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(debug_info, '\n'))

    -- Set the buffer to readonly
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    vim.api.nvim_buf_set_option(buf, 'readonly', true)

    -- Set buffer-local keymaps
    local opts = { noremap = true, silent = true }
    vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':close<CR>', opts)
    vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':close<CR>', opts)
end

return M

