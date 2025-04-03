# Configuration

This document explains the configuration options for nvim-http-client.

## Basic Configuration

The plugin can be configured using the `setup` function:

```lua
require("http_client").setup({
    -- Your configuration options here
})
```

## Full Configuration Example

Here's a complete configuration example using Lazy.nvim that you can copy and paste directly into your config:

```lua
{
    "heilgar/nvim-http-client",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "hrsh7th/nvim-cmp" -- Optional but recommended for enhanced autocompletion
    },
    event = "VeryLazy",
    ft = { "http", "rest" },
    keys = {
        { "<leader>he", "<cmd>HttpEnvFile<cr>",                          desc = "Select HTTP environment file" },
        { "<leader>hs", "<cmd>HttpSaveResponse<cr>",                     desc = "Save HttpResponse to file" },
        { "<leader>hr", "<cmd>HttpRun<cr>",                              desc = "Run HTTP request" },
        { "<leader>hx", "<cmd>HttpStop<cr>",                             desc = "Stop HTTP request" },
        { "<leader>hd", "<cmd>HttpDryRun<cr>",                           desc = "DryRun HTTP request" },
        { "<leader>hv", "<cmd>HttpVerbose<cr>",                          desc = "Toggle verbose for HTTP request" },
        { "<leader>ha", function() vim.cmd("HttpRunAll") end,            desc = "Run all HTTP requests" },
        { "<leader>hf", "<cmd>Telescope http_client http_env_files<cr>", desc = "Select HTTP env file (Telescope)" },
        { "<leader>hh", "<cmd>Telescope http_client http_envs<cr>",      desc = "Select HTTP env (Telescope)" },
        { "<leader>hp", "<cmd>HttpProfiling<cr>",                        desc = "Toggle HttpProfiling request profiling" },
        { "<leader>hc", "<cmd>HttpCopyCurl<cr>",                         desc = "Copy curl command for HTTP request" },
    },
    cmd = {
        "HttpEnvFile",
        "HttpEnv",
        "HttpRun",
        "HttpRunAll",
        "HttpStop",
        "HttpVerbose",
        "HttpDryRun",
        "HttpProfiling",
        "HttpCopyCurl",
        "HttpSaveResponse"
    },
    config = function()
        local http_client = require("http_client")
        http_client.setup({
            -- Default environment file to use
            default_env_file = '.env.json',
            
            -- Request timeout in milliseconds
            request_timeout = 30000, -- 30 seconds
            
            -- Split direction for response window ('right', 'left', 'top', 'bottom')
            split_direction = "right",
            
            -- Whether to create default keybindings (set to false when defining your own)
            create_keybindings = false,
            
            -- Profiling configuration
            profiling = {
                -- Enable request profiling
                enabled = true,
                -- Show timing metrics in response output
                show_in_response = true,
                -- Show detailed breakdown of timing metrics
                detailed_metrics = true,
            },
        })

        -- Set up Telescope integration
        if pcall(require, "telescope") then
            require("telescope").load_extension("http_client")
        end
        
        -- Configure nvim-cmp for HTTP files
        if pcall(require, "cmp") then
            local cmp = require("cmp")
            cmp.setup.filetype({ "http", "rest" }, {
                sources = cmp.config.sources({
                    { name = "http_method" },  -- HTTP methods (GET, POST, etc.)
                    { name = "http_header" },  -- HTTP headers
                    { name = "http_env_var" }, -- Environment variables
                    { name = "buffer" },       -- Buffer text for general completions
                })
            })
        end
    end,
}
```

## Configuration Options

Here are all the configuration options available:

### General Options

- `default_env_file` (string): Default environment file to use (default: '.env.json')
- `request_timeout` (number): Request timeout in milliseconds (default: 30000)
- `split_direction` (string): Direction to open response window ('right', 'left', 'top', 'bottom') (default: 'right')
- `create_keybindings` (boolean): Whether to create default keybindings (default: true)

### Profiling Options

- `profiling.enabled` (boolean): Enable request profiling (default: true)
- `profiling.show_in_response` (boolean): Show timing metrics in response output (default: true)
- `profiling.detailed_metrics` (boolean): Show detailed breakdown of timing metrics (default: true)

### Keybindings Options

If `create_keybindings` is true, the following keybindings will be created:

- `keybindings.select_env_file` (string): Keybinding to select environment file (default: "<leader>hf")
- `keybindings.set_env` (string): Keybinding to set current environment (default: "<leader>he")
- `keybindings.run_request` (string): Keybinding to run HTTP request under cursor (default: "<leader>hr")
- `keybindings.stop_request` (string): Keybinding to stop running HTTP request (default: "<leader>hx")
- `keybindings.dry_run` (string): Keybinding to perform dry run (default: "<leader>hd")
- `keybindings.toggle_verbose` (string): Keybinding to toggle verbose mode (default: "<leader>hv")
- `keybindings.copy_curl` (string): Keybinding to copy curl command (default: "<leader>hc")
- `keybindings.save_response` (string): Keybinding to save HTTP response (default: "<leader>hs")
- `keybindings.toggle_profiling` (string): Keybinding to toggle profiling (default: "<leader>hp")

This plugin can also be configured using the `after/plugin` directory. Create a file at `after/plugin/http_client.lua` in your Neovim configuration directory to override the default settings. 