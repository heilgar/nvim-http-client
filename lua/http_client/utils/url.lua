local M = {}

local url_escape_chars = {
    [" "] = "%20",
    ["!"] = "%21",
    ["#"] = "%23",
    ["$"] = "%24",
    ["%"] = "%25",
    ["&"] = "%26",
    ["'"] = "%27",
    ["("] = "%28",
    [")"] = "%29",
    ["*"] = "%2A",
    ["+"] = "%2B",
    [","] = "%2C",
    ["/"] = "%2F",
    [":"] = "%3A",
    [";"] = "%3B",
    ["="] = "%3D",
    ["?"] = "%3F",
    ["@"] = "%40",
    ["["] = "%5B",
    ["]"] = "%5D",
    ["{"] = "%7B",
    ["}"] = "%7D",
    ["|"] = "%7C",
    ["\\"] = "%5C",
    ["^"] = "%5E",
    ["~"] = "%7E",
    ["`"] = "%60",
    ['"'] = "%22",
    ["<"] = "%3C",
    [">"] = "%3E"
}

local function encode_component(str)
    if not str then return "" end

    -- First encode % to avoid double encoding
    str = str:gsub("%%", "%%25")

    -- Then encode other special characters
    str = str:gsub("([^%w%-%.%_])", function(c)
        return url_escape_chars[c] or c
    end)

    return str
end

local function split_url(url)
    local base_url, query = url:match("^(.-)%?(.*)$")
    if not base_url then
        return url, nil
    end
    return base_url, query
end

local function encode_query_params(query)
    if not query then return "" end

    -- Split on & to get individual key=value pairs
    local parts = vim.split(query, "&")
    local encoded_parts = {}

    for _, part in ipairs(parts) do
        local key, value = part:match("^([^=]*)=(.*)$")
        if key and value then
            -- Encode both key and value
            table.insert(encoded_parts,
                encode_component(key) .. "=" .. encode_component(value))
        else
            -- Handle cases where there's no value
            table.insert(encoded_parts, encode_component(part))
        end
    end

    return table.concat(encoded_parts, "&")
end

function M.encode_url(url)
    if not url then return url end

    local base_url, query = split_url(url)
    if not query then
        return base_url -- No query parameters to encode
    end

    return base_url .. "?" .. encode_query_params(query)
end

function M.needs_encoding(url)
    if not url then return false end

    for char, _ in pairs(url_escape_chars) do
        if url:find(char, 1, true) then
            return true
        end
    end
    return false
end

return M

