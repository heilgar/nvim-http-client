local M = {}

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
        local split_cmd
        local split_direction = require('http_client.config').get('split_direction')
        if split_direction == "right" then
            split_cmd = 'vsplit'
        elseif split_direction == "left" then
            split_cmd = 'leftabove vsplit'
        elseif split_direction == "below" then
            split_cmd = 'split'
        elseif split_direction == "above" then
            split_cmd = 'leftabove split'
        else
            split_cmd = 'vsplit' -- Default to right if invalid option
        end

        vim.cmd(split_cmd)
        local win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(win, buf)

        -- Set buffer to readonly
        vim.api.nvim_buf_set_option(buf, 'modifiable', false)
        vim.api.nvim_buf_set_option(buf, 'readonly', true)

        -- Set buffer-local keymaps
        local opts = { noremap = true, silent = true }
        vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':close<CR>', opts)
        vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':close<CR>', opts)

        vim.api.nvim_buf_set_option(buf, 'filetype', 'http_response')
    end)
end

return M

