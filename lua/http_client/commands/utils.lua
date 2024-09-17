local M = {}

local vvv = require('http_client.utils.verbose')
local parser = require('http_client.core.parser')
local environment = require('http_client.core.environment')
local http_client = require('http_client.core.http_client')
local curl_generator = require('http_client.core.curl_generator')

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

return M

