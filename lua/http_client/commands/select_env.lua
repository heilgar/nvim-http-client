local M = {}

local environment = require('http_client.core.environment')
local file_utils = require('http_client.utils.file_utils')

M.select_env_file = function(config)
    local files = file_utils.find_files('*.env.json')
    local default_file = config.default_env_file or '.env.json'
    local default_index = nil

    -- Find the index of the default file
    for i, file in ipairs(files) do
        if file:match(default_file .. "$") then
            default_index = i
            break
        end
    end

    vim.ui.select(files, {
        prompt = 'Select environment file:',
        default = default_index
    }, function(choice)
        if choice then
            environment.set_env_file(choice)
            print('\n\nEnvironment file set to: ' .. choice)
            -- Automatically select environment after file selection
            M.select_env()
        end
    end)
end

M.select_env = function()
    if not environment.get_current_env_file() then
        print('\nNo environment file selected. Please select an environment file first.')
        return
    end

    local env_data = file_utils.read_json_file(environment.get_current_env_file())
    if not env_data then
        print('\nFailed to read environment file')
        return
    end

    -- Set *default environment first
    local success = environment.set_env('*default')
    if success then
        print('\nEnvironment set to: *default')
    else
        print('\nFailed to set default environment')
        return
    end

    local env_names = { '*default' }
    for name, _ in pairs(env_data) do
        if name ~= '*default' then
            table.insert(env_names, name)
        end
    end

    vim.ui.select(env_names, {
        prompt = 'Select environment (current: *default):',
    }, function(choice)
        if choice and choice ~= '*default' then
            local success = environment.set_env(choice)
            if success then
                print('\nEnvironment set to: ' .. choice)
            else
                print('\nFailed to set environment: ' .. choice)
            end
        end
    end)
end


return M

