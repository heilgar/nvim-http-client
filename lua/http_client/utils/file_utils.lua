local M = {}

M.find_files = function(pattern)
    local handle = io.popen('find . -name "' .. pattern .. '"')
    local result = handle:read("*a")
    handle:close()

    local files = {}
    for file in result:gmatch("[^\r\n]+") do
        local filename = file:sub(3) -- remove './' from the beginning
        -- Exclude files with ".private." in their name
        if not filename:match("%.private%.") then
            table.insert(files, filename)
        end
    end
    return files
end

M.read_json_file = function(file_path)
    local file = io.open(file_path, "r")
    if not file then return nil end

    local content = file:read("*all")
    file:close()

    local ok, parsed = pcall(vim.fn.json_decode, content)
    if not ok then return nil end

    return parsed
end

return M

