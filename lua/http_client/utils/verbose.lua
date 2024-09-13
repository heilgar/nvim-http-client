local M = {}

_G.http_verbose_mode = false

M.set_verbose_mode = function(enabled)
    _G.http_verbose_mode = enabled
    M.debug_print(string.format("Verbose mode %s", enabled and "enabled" or "disabled"))
end

M.get_verbose_mode = function()
    return _G.http_verbose_mode
end


M.debug_print = function(message)
    if _G.http_verbose_mode then
        print(string.format("[HTTP Client Debug] %s", message))
    end
end


return M

