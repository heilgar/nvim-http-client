local M = {}
local environment = require('http_client.core.environment')

-- Cache for recently used variables
local recent_vars = {}
local MAX_RECENT_VARS = 10

-- Common HTTP methods
local HTTP_METHODS = {
    { label = "GET", documentation = "Retrieve data from the server" },
    { label = "POST", documentation = "Send data to the server to create a resource" },
    { label = "PUT", documentation = "Update an existing resource on the server" },
    { label = "DELETE", documentation = "Remove a resource from the server" },
    { label = "PATCH", documentation = "Partially update a resource" },
    { label = "HEAD", documentation = "Same as GET but without the response body" },
    { label = "OPTIONS", documentation = "Describe the communication options for the target resource" },
    { label = "TRACE", documentation = "Perform a message loop-back test along the path to the target resource" },
    { label = "CONNECT", documentation = "Establish a tunnel to the server identified by the target resource" }
}

-- Common HTTP headers
local HTTP_HEADERS = {
    { label = "Accept", documentation = "Media types that are acceptable for the response" },
    { label = "Accept-Charset", documentation = "Character sets that are acceptable" },
    { label = "Accept-Encoding", documentation = "List of acceptable encodings" },
    { label = "Accept-Language", documentation = "List of acceptable human languages for response" },
    { label = "Authorization", documentation = "Authentication credentials for HTTP authentication" },
    { label = "Cache-Control", documentation = "Directives for caching mechanisms in requests and responses" },
    { label = "Connection", documentation = "Control options for the current connection" },
    { label = "Content-Disposition", documentation = "Information about how the content should be presented" },
    { label = "Content-Encoding", documentation = "The type of encoding used on the data" },
    { label = "Content-Length", documentation = "The length of the request body in octets" },
    { label = "Content-Type", documentation = "The media type of the body of the request" },
    { label = "Cookie", documentation = "An HTTP cookie previously sent by the server" },
    { label = "Date", documentation = "The date and time that the message was sent" },
    { label = "Host", documentation = "The domain name of the server and the TCP port number" },
    { label = "Origin", documentation = "Initiates a request for cross-origin resource sharing" },
    { label = "Referer", documentation = "The address of the previous web page" },
    { label = "User-Agent", documentation = "The user agent string of the user agent" },
    { label = "X-Requested-With", documentation = "Mainly used to identify Ajax requests" }
}

-- Common content types
local CONTENT_TYPES = {
    { label = "application/json", documentation = "JSON data" },
    { label = "application/xml", documentation = "XML data" },
    { label = "application/x-www-form-urlencoded", documentation = "Form URL encoded data" },
    { label = "multipart/form-data", documentation = "Multipart form data, used for file uploads" },
    { label = "text/plain", documentation = "Plain text" },
    { label = "text/html", documentation = "HTML content" },
    { label = "text/css", documentation = "CSS content" },
    { label = "text/javascript", documentation = "JavaScript content" },
    { label = "application/octet-stream", documentation = "Binary data" }
}

-- Add a variable to the recent vars cache
local function add_to_recent(var)
    -- Remove if already in list
    for i, v in ipairs(recent_vars) do
        if v == var then
            table.remove(recent_vars, i)
            break
        end
    end
    
    -- Add to front
    table.insert(recent_vars, 1, var)
    
    -- Trim to max size
    if #recent_vars > MAX_RECENT_VARS then
        table.remove(recent_vars)
    end
end

-- Get all available variables from current environment
local function get_env_variables()
    local env = environment.get_current_env() or {}
    local env_vars = {}
    
    -- Add environment variables
    for key, _ in pairs(env) do
        if type(key) == "string" and not key:match("^%*") then -- Skip environment metadata like *default
            table.insert(env_vars, {
                name = key,
                source = "Environment",
                value = tostring(env[key])
            })
        end
    end
    
    -- Add global variables
    local global_vars = environment.get_global_variables() or {}
    for key, value in pairs(global_vars) do
        if type(key) == "string" then
            table.insert(env_vars, {
                name = key,
                source = "Global",
                value = tostring(value)
            })
        end
    end
    
    -- Add recently used variables that aren't in the other lists
    for _, var in ipairs(recent_vars) do
        local exists = false
        for _, env_var in ipairs(env_vars) do
            if env_var.name == var then
                exists = true
                break
            end
        end
        
        if not exists then
            table.insert(env_vars, {
                name = var,
                source = "Recent",
                value = "Recently used"
            })
        end
    end
    
    return env_vars
end

-- Check if nvim-cmp is available
local has_cmp = (function()
    local ok, _ = pcall(require, "cmp")
    return ok
end)()

-- Track usage of environment variables in files
M.track_env_var_usage = function()
    local bufnr = vim.api.nvim_get_current_buf()
    
    -- Get all lines in the buffer
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    
    -- Find all environment variables in the buffer
    for _, line in ipairs(lines) do
        for var in line:gmatch("{{([^}]+)}}") do
            var = var:match("^%s*(.-)%s*$") -- Trim whitespace
            if var and var ~= "" then
                add_to_recent(var)
            end
        end
    end
end

-- Legacy omnifunc for environment variables (used as fallback if nvim-cmp isn't available)
M.env_var_completion = function(_, _, _)
    local line = vim.api.nvim_get_current_line()
    local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
    
    -- Only provide completions inside {{...}}
    local before_cursor = line:sub(1, cursor_col)
    local opens_count = 0
    local opens_pos = {}
    
    -- Find opening braces
    for i = 1, #before_cursor - 1 do
        if before_cursor:sub(i, i+1) == "{{" then
            opens_count = opens_count + 1
            opens_pos[opens_count] = i
        end
    end
    
    -- Find closing braces
    for i = 1, #before_cursor - 1 do
        if before_cursor:sub(i, i+1) == "}}" then
            opens_count = opens_count - 1
            if opens_count < 0 then
                opens_count = 0
            end
        end
    end
    
    -- If cursor is not inside {{ }}, no completions
    if opens_count == 0 then
        return {}
    end
    
    -- Extract the text between {{ and cursor
    local last_open = opens_pos[opens_count]
    local prefix = before_cursor:sub(last_open + 2):gsub("^%s+", "")  -- Trim leading whitespace
    
    -- Get all env variables
    local items = {}
    local env_vars = get_env_variables()
    
    -- Filter variables by prefix
    for _, var in ipairs(env_vars) do
        if var.name:sub(1, #prefix) == prefix then
            table.insert(items, {
                label = var.name,
                kind = vim.lsp.protocol.CompletionItemKind.Variable,
                insertText = var.name,
                documentation = string.format("%s variable: %s\nValue: %s", 
                    var.source, var.name, var.value)
            })
            
            -- Add to recent on selection
            if prefix == var.name then
                add_to_recent(var.name)
            end
        end
    end
    
    return {
        items = items,
        isIncomplete = true
    }
end

-- Legacy completefunc for HTTP methods and headers (used as fallback if nvim-cmp isn't available)
M.http_completion = function(findstart, base)
    if findstart == 1 then
        local line = vim.api.nvim_get_current_line()
        local col = vim.api.nvim_win_get_cursor(0)[2]
        
        -- Check if we're at the start of the line - method completion
        if col == 0 or line:sub(1, col):match("^%s*$") then
            return 0  -- Complete from the start of the line
        end
        
        -- Check if we're after a method - URL completion
        if line:match("^%s*[A-Z]+%s+") and not line:match(":") then
            local method_end = line:find("%s+")
            if method_end and col >= method_end then
                return method_end  -- Complete from after the method
            end
        end
        
        -- Check if we're at header name position
        local start_col = line:find("^%s*[%w%-]+:?%s*")
        if start_col and not line:find(":", 1, true) then
            return 0  -- Complete from the start of the line
        end
        
        -- Check if we're completing a Content-Type or Accept value
        if line:match("^%s*[Cc]ontent%-[Tt]ype:%s*") or line:match("^%s*[Aa]ccept:%s*") then
            local colon_pos = line:find(":", 1, true)
            if colon_pos and col > colon_pos then
                return colon_pos + 1  -- Complete from after the colon
            end
        end
        
        return -1  -- No completion
    else
        local line = vim.api.nvim_get_current_line()
        local col = vim.api.nvim_win_get_cursor(0)[2]
        local items = {}
        
        -- Method completion
        if line == "" or line:match("^%s*$") or (col == 0 and base == "") then
            for _, method in ipairs(HTTP_METHODS) do
                table.insert(items, {
                    word = method.label,
                    kind = "Method",
                    info = method.documentation,
                    icase = 1,
                    dup = 0,
                    empty = 1
                })
            end
            return items
        end
        
        -- Content-Type or Accept value completion
        if line:match("^%s*[Cc]ontent%-[Tt]ype:%s*") or line:match("^%s*[Aa]ccept:%s*") then
            for _, ct in ipairs(CONTENT_TYPES) do
                if ct.label:lower():find(base:lower(), 1, true) == 1 or base == "" then
                    table.insert(items, {
                        word = ct.label,
                        kind = "Value",
                        info = ct.documentation,
                        icase = 1,
                        dup = 0,
                        empty = 1
                    })
                end
            end
            return items
        end
        
        -- Header completion
        if line:match("^%s*$") or (not line:find(":", 1, true) and col <= #line) then
            for _, header in ipairs(HTTP_HEADERS) do
                if header.label:lower():find(base:lower(), 1, true) == 1 then
                    table.insert(items, {
                        word = header.label .. ": ",
                        kind = "Field",
                        info = header.documentation,
                        icase = 1,
                        dup = 0,
                        empty = 1
                    })
                end
            end
            
            return items
        end
        
        return {}
    end
end

-- ------------------------------------------------
-- nvim-cmp Source for HTTP Methods
-- ------------------------------------------------
M.create_method_source = function()
    return {
        option = {
            keyword_pattern = [[\w\+]],
        },
        is_available = function()
            return vim.bo.filetype == "http" or vim.bo.filetype == "rest"
        end,
        get_trigger_characters = function()
            -- Add empty string to trigger at the beginning of a line
            return { '' }
        end,
        get_keyword_pattern = function()
            -- Make sure to match methods at the start of a line
            return [[^\s*\zs\w\+\ze]]
        end,
        complete = function(_, request, callback)
            local line = request.context.cursor_line
            local cursor_col = request.context.cursor.col
            local line_num = vim.api.nvim_win_get_cursor(0)[1]
            
            -- Only provide method completions at the start of a line
            if cursor_col > 1 and not line:sub(1, cursor_col-1):match("^%s*$") then
                callback({ items = {}, isIncomplete = false })
                return
            end
            
            -- Check if we're in a good context for method completion:
            -- 1. Previous line must be a ### divider, or empty line after a request
            local valid_context = false
            
            if line_num == 1 then
                valid_context = true -- First line of file is always valid
            elseif line_num > 1 then
                local prev_line = vim.api.nvim_buf_get_lines(0, line_num - 2, line_num - 1, false)[1]
                if prev_line and prev_line:match("^%s*###") then
                    valid_context = true -- Line after the divider is valid for method
                elseif prev_line and prev_line:match("^%s*$") then
                    -- Check if we're in a request body
                    local in_body = false
                    -- Look up at previous lines to see if we find a request line before empty line
                    for i = line_num - 2, math.max(line_num - 10, 1), -1 do
                        local check_line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
                        if check_line and check_line:match("^%s*[A-Z]+%s+%S+") then
                            in_body = true
                            break
                        elseif check_line and check_line:match("^%s*###") then
                            -- Found divider before request, not in body
                            break
                        end
                    end
                    if not in_body then
                        valid_context = true -- Empty line not in request body
                    end
                end
            end
            
            if not valid_context then
                callback({ items = {}, isIncomplete = false })
                return
            end
            
            -- Check if we already have a method on this line (we shouldn't)
            if line:match("^%s*[A-Z]+%s+%S+") then
                callback({ items = {}, isIncomplete = false })
                return
            end
            
            local items = {}
            for _, method in ipairs(HTTP_METHODS) do
                -- Make matching more flexible - case insensitive
                local input_text = request.context.cursor_before_line:match("^%s*(.*)$") or ""
                if input_text == "" or method.label:lower():find(input_text:lower(), 1, true) == 1 then
                    table.insert(items, {
                        label = method.label,
                        kind = 5, -- Function
                        documentation = {
                            kind = "markdown",
                            value = "**" .. method.label .. "**\n\n" .. method.documentation
                        },
                        insertText = method.label .. " ",
                    })
                end
            end
            
            callback({ items = items, isIncomplete = true })
        end
    }
end

-- ------------------------------------------------
-- nvim-cmp Source for HTTP Headers
-- ------------------------------------------------
M.create_header_source = function()
    return {
        option = {
            keyword_pattern = [[\w\+]],
        },
        is_available = function()
            return vim.bo.filetype == "http" or vim.bo.filetype == "rest"
        end,
        get_trigger_characters = function()
            -- Add triggers for content type suggestions after colon or space
            return { 'A', 'C', 'H', 'U', 'a', 'c', 'h', 'u', ':', ' ', 'j', 'x', 'm', 't', 'p', 'l', 'f', 'o', 'r', 'm' }
        end,
        get_keyword_pattern = function()
            -- Pattern for header names at the start of a line and values after the colon
            return [[^\s*\zs\(\w\|-\)\+\ze:\|^\s*\(\w\|-\)\+:\s*\zs\S*\ze]]
        end,
        complete = function(_, request, callback)
            local line = request.context.cursor_line
            local cursor_col = request.context.cursor.col
            local before_cursor = line:sub(1, cursor_col)
            
            -- Skip if we're in the first line (usually the request line with the HTTP method)
            local line_num = vim.api.nvim_win_get_cursor(0)[1]
            local is_first_line = (line_num == 1)
            
            -- Check for request line pattern (HTTP method + URL)
            local is_request_line = line:match("^%s*[A-Z]+%s+%S+") ~= nil
            
            if is_first_line or is_request_line then
                callback({ items = {}, isIncomplete = false })
                return
            end
            
            local items = {}
            
            -- Extract header name and any partial value typed after the colon
            local header_match = before_cursor:match("^%s*([^:]+):%s*(.*)$")
            
            -- If we detected a header with a colon (header value completion)
            if header_match then
                local header_name = header_match:match("^([^:]+)")
                if not header_name then
                    header_name = ""
                end
                
                header_name = header_name:lower():gsub("^%s+", ""):gsub("%s+$", "")
                
                -- Special handling for Content-Type or Accept headers
                if header_name == "content-type" or header_name == "accept" then
                    -- Get whatever has been typed after the colon
                    local value_prefix = before_cursor:match("^%s*[^:]+:%s*(.*)$") or ""
                    value_prefix = value_prefix:lower():gsub("^%s+", "")
                    
                    for _, ct in ipairs(CONTENT_TYPES) do
                        if value_prefix == "" or ct.label:lower():find(value_prefix, 1, true) == 1 then
                            table.insert(items, {
                                label = ct.label,
                                kind = 12, -- Value
                                documentation = {
                                    kind = "markdown",
                                    value = "**" .. ct.label .. "**\n\n" .. ct.documentation
                                }
                            })
                        end
                    end
                    
                    callback({ items = items, isIncomplete = true })
                    return
                end
                
                -- For other headers, no completions after the colon
                callback({ items = {}, isIncomplete = false })
                return
            end
            
            -- Header name completion (for headers without a colon yet)
            -- This is for when user is typing a new header name at start of line
            local current_input = before_cursor:match("^%s*(.*)$") or ""
            current_input = current_input:lower()
            
            for _, header in ipairs(HTTP_HEADERS) do
                if current_input == "" or header.label:lower():find(current_input, 1, true) == 1 then
                    table.insert(items, {
                        label = header.label,
                        kind = 6, -- Field
                        documentation = {
                            kind = "markdown",
                            value = "**" .. header.label .. "**\n\n" .. header.documentation
                        },
                        insertText = header.label .. ": ",
                    })
                end
            end
            
            callback({ items = items, isIncomplete = true })
        end
    }
end

-- ------------------------------------------------
-- nvim-cmp Source for Environment Variables
-- ------------------------------------------------
M.create_env_var_source = function()
    return {
        is_available = function()
            return vim.bo.filetype == "http" or vim.bo.filetype == "rest"
        end,
        get_trigger_characters = function()
            -- Trigger on every possible character that could be in a variable name
            return { "{", "}", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", 
                    "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", 
                    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", 
                    "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
                    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "_" }
        end,
        get_keyword_pattern = function()
            -- Match everything after {{ until }}
            return [[{{[^}]*}}?]]
        end,
        complete = function(self, request, callback)
            local cursor_before_line = request.context.cursor_before_line
            
            -- Check if we're typing inside {{ but before }}
            local match_start, match_end = cursor_before_line:find("{{[^}]*$")
            
            if not match_start then
                callback({ items = {}, isIncomplete = false })
                return
            end
            
            -- Extract what user has typed after {{
            local prefix = cursor_before_line:sub(match_start + 2):gsub("^%s+", "")  -- Trim leading whitespace
            
            local items = {}
            local env_vars = get_env_variables()
            
            -- Collect all matching variables based on prefix
            for _, var in ipairs(env_vars) do
                -- Case insensitive match that shows variables starting with what's been typed
                if prefix == "" or var.name:lower():find(prefix:lower(), 1, true) == 1 then
                    table.insert(items, {
                        label = var.name,
                        filterText = var.name,  -- Ensure filtering uses the variable name
                        kind = 6, -- Variable 
                        documentation = {
                            kind = "markdown",
                            value = string.format("**%s Variable**\n\nName: %s\nValue: %s", 
                                var.source, var.name, var.value)
                        },
                        insertText = var.name,
                    })
                    
                    -- Add to recent variables cache when selected
                    if prefix == var.name then
                        add_to_recent(var.name)
                    end
                end
            end
            
            -- Force completion window to stay open while typing
            callback({ 
                items = items, 
                isIncomplete = true 
            })
        end
    }
end

-- Setup function for registering completion source
M.setup = function()
    -- Set up nvim-cmp sources if available
    if has_cmp then
        local cmp = require("cmp")
        
        -- Register HTTP Method source
        cmp.register_source('http_method', M.create_method_source())
        
        -- Register HTTP Header source
        cmp.register_source('http_header', M.create_header_source())
        
        -- Register HTTP Environment Variable source  
        cmp.register_source('http_env_var', M.create_env_var_source())
        
        -- Add sources to filetype configuration
        cmp.setup.filetype({ 'http', 'rest' }, {
            sources = cmp.config.sources({
                { name = 'http_method' },
                { name = 'http_header' },
                { name = 'http_env_var' },
                { name = 'buffer' },
            })
        })
    end
    
    -- Fallback for when nvim-cmp isn't available: set up traditional Vim completion
    vim.api.nvim_create_autocmd("FileType", {
        pattern = {"http", "rest"},
        callback = function()
            -- Set up omnifunc for env variable completion
            vim.api.nvim_buf_set_option(0, 'omnifunc', 'v:lua.require("http_client.completion").env_var_completion')
            
            -- Set up completefunc for HTTP methods and headers
            vim.api.nvim_buf_set_option(0, 'completefunc', 'v:lua.require("http_client.completion").http_completion')
            
            -- Track environment variable usage when the file is loaded
            M.track_env_var_usage()
            
            -- Add triggers if nvim-cmp isn't available
            if not has_cmp then
                -- Auto-trigger environment variable completion
                vim.keymap.set('i', '{{', '{{<C-X><C-O>', { buffer = true, noremap = true, silent = true })
                
                -- Auto-trigger header completion on newline
                vim.keymap.set('i', '<CR>', '<CR><C-X><C-U>', { buffer = true, noremap = true, silent = true })
            end
        end
    })
    
    -- Track environment variable usage when saving a file
    vim.api.nvim_create_autocmd("BufWritePost", {
        pattern = {"*.http", "*.rest"},
        callback = function()
            M.track_env_var_usage()
        end
    })
end

return M 