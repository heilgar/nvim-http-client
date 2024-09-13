local M = {}
local file_utils = require('http_client.file_utils')

local current_env_file = nil
local current_private_env_file = nil
local current_env = nil

M.set_env_file = function(file_path)
    current_env_file = file_path
    -- Reset current environment when changing file
    current_env = nil

    -- Set the private environment file path
    current_private_env_file = file_path:gsub("%.env%.json$", ".private.env.json")

    -- Check if the private file exists
    if vim.fn.filereadable(current_private_env_file) ~= 1 then
        current_private_env_file = nil
    end
end

M.set_env = function(env_name)
    if not current_env_file then
        print('No environment file selected')
        return false
    end

    local env_data = file_utils.read_json_file(current_env_file)
    if not env_data then
        print('Failed to read environment file')
        return false
    end

    -- Start with an empty environment
    current_env = {}

    -- Merge default environment if it exists
    if env_data['*default'] then
        current_env = vim.tbl_deep_extend('force', current_env, env_data['*default'])
    end

    -- Merge selected environment
    if env_data[env_name] then
        current_env = vim.tbl_deep_extend('force', current_env, env_data[env_name])
    end

    -- Merge with private environment if it exists
    if current_private_env_file then
        local private_env_data = file_utils.read_json_file(current_private_env_file)
        if private_env_data then
            -- Merge private default environment if it exists
            if private_env_data['*default'] then
                current_env = vim.tbl_deep_extend('force', current_env, private_env_data['*default'])
            end
            -- Merge private selected environment if it exists
            if private_env_data[env_name] then
                current_env = vim.tbl_deep_extend('force', current_env, private_env_data[env_name])
            end
        end
    end

    return true
end

M.get_current_env = function()
    return current_env or {}
end

M.get_current_env_file = function()
    return current_env_file
end

M.get_current_private_env_file = function()
    return current_private_env_file
end

M.get_ssl_config = function()
    if current_env and current_env.SSLConfiguration then
        return current_env.SSLConfiguration
    end
    return {}
end

return M

