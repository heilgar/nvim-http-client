local M = {}
local file_utils = require('http_client.file_utils')

local current_env_file = nil
local current_env = nil

M.set_env_file = function(file_path)
    current_env_file = file_path
    -- Reset current environment when changing file
    current_env = nil
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

    local default_env = env_data['*default'] or {}
    local selected_env = env_data[env_name] or {}

    current_env = vim.tbl_deep_extend('force', default_env, selected_env)
    return true
end

M.get_current_env = function()
    return current_env or {}
end

M.get_current_env_file = function()
    return current_env_file
end

return M

