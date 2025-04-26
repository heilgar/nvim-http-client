local M = {}
local state = require('http_client.state')
local file_utils = require('http_client.utils.file_utils')

M.save_response = function(opts)
    local response = state.get_current_response()
    if not response then
        vim.notify("No response available to save", vim.log.levels.WARN)
        return
    end

    local function get_extension_for_content_type(content_type)
        if content_type == "json" then
            return ".json"
        elseif content_type == "xml" then
            return ".xml"
        elseif content_type == "html" then
            return ".html"
        elseif content_type == "csv" then
            return ".csv"
        else
            return ".txt"
        end
    end

    local default_ext = get_extension_for_content_type(response.content_type)
    local content = opts and opts.raw and response.raw_body or response.formatted_body

    vim.ui.input({
        prompt = "Save response as (default extension: " .. default_ext .. "): ",
        default = "response" .. default_ext,
        completion = "file"
    }, function(filename)
        if not filename then return end

        -- Add default extension if none provided
        if not filename:match("%.%w+$") then
            filename = filename .. default_ext
        end

        -- Write the file using our utility
        local success, err = file_utils.write_file(filename, content)

        if success then
            vim.notify(string.format("Response saved to: %s (%s)",
                    filename,
                    opts and opts.raw and "raw" or "formatted"),
                vim.log.levels.INFO)
        else
            vim.notify("Failed to save response: " .. tostring(err), vim.log.levels.ERROR)
        end
    end)
end


return M

