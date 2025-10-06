local M = {}
local Path = require('plenary.path')

-- Store the project root globally
M.project_root = vim.fn.getcwd()

M.set_project_root = function(root_path)
    if root_path then
        M.project_root = root_path
    else
        M.project_root = vim.fn.getcwd()
    end
end

M.get_project_root = function()
    return M.project_root
end

M.find_files = function(pattern, project_root)
    local search_root = project_root or M.project_root
    
    local handle = io.popen('find "' .. search_root .. '" -name "' .. pattern .. '"')
    local result = handle:read("*a")
    handle:close()

    local files = {}
    for file in result:gmatch("[^\r\n]+") do
        -- Remove the search root prefix from the file path
        local filename = file:sub(#search_root + 2) -- +2 to remove the '/' after the root
        -- Exclude files with ".private." in their name
        if not filename:match("%.private%.") then
            table.insert(files, filename)
        end
    end
    
    return files
end

M.read_json_file = function(file_path)
    -- If the path is relative, make it absolute using the project root
    if not file_path:match("^/") then
        file_path = M.project_root .. "/" .. file_path
    end
    
    local file = io.open(file_path, "r")
    if not file then return nil end

    local content = file:read("*all")
    file:close()

    local ok, parsed = pcall(vim.fn.json_decode, content)
    if not ok then return nil end

    return parsed
end

M.write_file = function(filename, content)
    local path = Path:new(filename)

    local parent = path:parent()
    local mkdir_ok, mkdir_err = pcall(function()
        parent:mkdir({ parents = true })
    end)

    if not mkdir_ok then
        return false, string.format("Failed to create directory: %s", mkdir_err)
    end

    local write_ok, write_err = pcall(function()
        path:write(content, 'w')
    end)

    if not write_ok then
        return false, string.format("Failed to write file: %s", write_err)
    end

    return true, nil
end

return M

