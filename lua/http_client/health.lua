local health = vim.health or require("health")

local M = {}

M.check = function()
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

    -- Check if curl is available
    local curl_check = vim.fn.system("which curl")
    if vim.v.shell_error == 0 then
        health.ok("curl is available")
    else
        health.error("curl is not available", "Install curl")
    end
end

return M

