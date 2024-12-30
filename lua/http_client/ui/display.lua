local M = {}
local response_win = nil
local buffers = {}
local MAX_BUFFERS = 10

local function get_timestamp()
    return os.date("%H:%M:%S")
end

local function navigate_buffers(direction)
    if not response_win or not vim.api.nvim_win_is_valid(response_win) then
        return
    end

    local current_buf = vim.api.nvim_win_get_buf(response_win)
    local current_idx = nil

    -- Find current buffer index
    for i, buf in ipairs(buffers) do
        if buf == current_buf then
            current_idx = i
            break
        end
    end

    if not current_idx then return end

    -- Calculate next buffer index
    local next_idx
    if direction == 'next' then
        next_idx = current_idx == 1 and #buffers or current_idx - 1
    else
        next_idx = current_idx == #buffers and 1 or current_idx + 1
    end

    -- Set the buffer in our response window
    if buffers[next_idx] and vim.api.nvim_buf_is_valid(buffers[next_idx]) then
        vim.api.nvim_win_set_buf(response_win, buffers[next_idx])
    end
end

local function create_response_buffer()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'swapfile', false)
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'hide')
    vim.api.nvim_buf_set_option(buf, 'filetype', 'http_response')

    -- Set buffer-local keymaps
    local opts = { noremap = true, silent = true, callback = function() end }
    vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':close<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':close<CR>', { noremap = true, silent = true })
    -- Add custom navigation commands
    vim.api.nvim_buf_set_keymap(buf, 'n', 'H', '', {
        noremap = true,
        silent = true,
        callback = function() navigate_buffers('prev') end
    })
    vim.api.nvim_buf_set_keymap(buf, 'n', 'L', '', {
        noremap = true,
        silent = true,
        callback = function() navigate_buffers('next') end
    })

    -- Add to our buffer list
    table.insert(buffers, 1, buf)

    -- Remove oldest buffer if we exceed MAX_BUFFERS
    if #buffers > MAX_BUFFERS then
        local old_buf = table.remove(buffers)
        if vim.api.nvim_buf_is_valid(old_buf) then
            vim.api.nvim_buf_delete(old_buf, { force = true })
        end
    end

    return buf
end

local function get_response_win()
    if response_win and vim.api.nvim_win_is_valid(response_win) then
        return response_win
    end

    -- Find any existing window with our buffers
    for _, buf in pairs(buffers) do
        if vim.api.nvim_buf_is_valid(buf) then
            for _, win in ipairs(vim.api.nvim_list_wins()) do
                if vim.api.nvim_win_get_buf(win) == buf then
                    response_win = win
                    return win
                end
            end
        end
    end

    return nil
end

local function create_response_win()
    local split_direction = require('http_client.config').get('split_direction')
    local split_cmd
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

    -- Store current window to return to it
    local current_win = vim.api.nvim_get_current_win()

    vim.cmd(split_cmd)
    response_win = vim.api.nvim_get_current_win()

    -- Return to original window
    vim.api.nvim_set_current_win(current_win)

    return response_win
end

function M.display_in_buffer(content, title)
    vim.schedule(function()
        local timestamp = get_timestamp()
        -- Create new buffer for this response
        local buf = create_response_buffer()

        -- Try to get existing window or create new one
        local win = get_response_win() or create_response_win()

        -- Set buffer name with timestamp
        local buf_name = string.format("[%s] %s", timestamp, title)
        pcall(vim.api.nvim_buf_set_name, buf, buf_name)

        -- Make buffer modifiable
        vim.api.nvim_buf_set_option(buf, 'modifiable', true)

        -- Set content
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, '\n'))

        -- Set buffer to readonly
        vim.api.nvim_buf_set_option(buf, 'modifiable', false)
        vim.api.nvim_buf_set_option(buf, 'readonly', true)

        -- Set buffer in window
        vim.api.nvim_win_set_buf(win, buf)
    end)
end

return M

