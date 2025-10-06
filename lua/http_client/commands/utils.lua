local M = {}

local parser = require('http_client.core.parser')
local environment = require('http_client.core.environment')
local curl_generator = require('http_client.core.curl_generator')
local file_utils = require('http_client.utils.file_utils')

M.copy_curl = function()
    local request = parser.get_request_under_cursor()
    if not request then
        print('\nNo valid HTTP request found under cursor')
        return
    end

    local env = environment.get_current_env()
    request = parser.replace_placeholders(request, env)

    local curl_command = curl_generator.generate_curl(request)
    vim.fn.setreg('+', curl_command)
    print('Curl command copied to clipboard')
end

M.set_project_root = function(root_path)
    if root_path and root_path ~= "" then
        file_utils.set_project_root(root_path)
        print(string.format("Project root set to: %s", root_path))
    else
        -- Prompt user for the project root path
        local input = vim.fn.input("Enter project root path (or press Enter to reset to current directory): ")
        if input and input ~= "" then
            file_utils.set_project_root(input)
            print(string.format("Project root set to: %s", input))
        else
            file_utils.set_project_root()
            print(string.format("Project root reset to current directory: %s", vim.fn.getcwd()))
        end
    end
end

M.get_project_root = function()
    local root = file_utils.get_project_root()
    print(string.format("Current project root: %s", root))
    return root
end

M.debug_env = function()
    local root = file_utils.get_project_root()
    local env_file = environment.get_current_env_file()

    print(string.format("Project root: %s", root))
    print(string.format("Current working directory: %s", vim.fn.getcwd()))
    print(string.format("Environment file: %s", env_file or "None"))

    if env_file then
        local exists = vim.fn.filereadable(env_file) == 1
        print(string.format("Environment file exists: %s", exists and "Yes" or "No"))
    end
end

return M
