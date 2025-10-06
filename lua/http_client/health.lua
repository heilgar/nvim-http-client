local health = vim.health or require("health")
local config = require("http_client.config")

local M = {}

M.check = function()
    local cfg = M.config or config
    if cfg.setup then
        cfg.setup()
    end
    health.start("http_client")

    -- Check if required dependencies are available
    if pcall(require, "plenary") then
        health.ok("plenary.nvim is installed")
    else
        health.error("plenary.nvim is not installed", "Install plenary.nvim")
    end

    -- Check Telescope integration
    if pcall(require, "telescope") then
        health.ok("telescope.nvim is installed")

        -- Safely check if the extension is loaded
        local telescope = require("telescope")
        if telescope.extensions and telescope.extensions["http_client"] then
            health.ok("Telescope HTTP Client extension is properly loaded")
        else
            health.warn("Telescope HTTP Client extension is not loaded",
                "Make sure to load the extension with require('telescope').load_extension('http_client')")
        end
    else
        health.warn("telescope.nvim is not installed", "Install telescope.nvim for enhanced environment selection")
    end
    
    -- Check for nvim-cmp integration
    if pcall(require, "cmp") then
        health.ok("nvim-cmp is installed")
        
        -- Check if our sources are registered
        local cmp = require("cmp")
        local source_available = false
        
        -- Try to access the source (we can't directly check if registered, but we can check if our files exist)
        if pcall(require, "http_client.completion") then
            health.ok("HTTP Client completion module is available")
            health.info("Using enhanced nvim-cmp autocompletion")
        else
            health.warn("HTTP Client completion module is not properly loaded")
        end
    else
        health.info("nvim-cmp not installed, using fallback completion methods")
        health.info("For enhanced autocompletion, install nvim-cmp")
    end

    -- Check if curl is available
    local curl_check = vim.fn.system("which curl")
    if vim.v.shell_error == 0 then
        health.ok("curl is available")
    else
        health.error("curl is not available", "Install curl")
    end

    -- Check if profiling is enabled
    local profiling_config = cfg.get('profiling')
    if profiling_config and profiling_config.enabled then
        health.ok('Profiling: enabled')
    else
        health.info('Profiling: disabled (use :HttpProfiling to enable)')
    end

    -- Check other parts of the plugin
end

return M

