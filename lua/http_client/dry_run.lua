local M = {}

local function format_headers(headers)
    local formatted = {}
    for k, v in pairs(headers or {}) do
        table.insert(formatted, string.format("%s: %s", k, v))
    end
    return table.concat(formatted, "\n")
end


function M.display_dry_run(http_client)
    local parser = http_client.parser
    local request = parser.get_request_under_cursor()
    if not request then
        print('No valid HTTP request found under cursor')
        return
    end

    local env = http_client.environment.get_current_env()
    request = parser.replace_placeholders(request, env)

    local env_file = http_client.environment.get_current_env_file() or "Not set"
    local private_env = http_client.environment.get_current_private_env_file() or "Not set"

    local env_info = vim.inspect(env or {})
    local current_request = vim.inspect(http_client.http_client.get_current_request() or {})


    local ui = require('http_client.ui')

    local content = string.format([[
Dry Run Information (%s):
--------------------
%s %s
# Status: %s

# Headers:
%s

# Body:
%s

Environment Information:
------------------------
Current env file: %s
Current private env file: %s

Current env:
%s

Current request:
%s
]],
        request.test_name or "N/A",
        request.method,
        request.url,
        request.status or "N/A",
        format_headers(request.headers),
        request.body or "No body",
        env_file,
        private_env,
        env_info,
        current_request
    )

    ui.display_in_buffer(content, "HTTP Request Dry Run")
end

return M

