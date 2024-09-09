# Neovim HTTP Request Plugin

A Neovim plugin for running HTTP requests directly from .http files, with support for environment variables.

## Features

- Run HTTP requests from .http files
- Support for environment variables
- Easy switching between different environments
- Non-blocking requests
- Pretty-printed response display in a separate buffer
- Automatic formatting for JSON and XML responses
- Syntax highlighting based on content type
- Verbose mode for debugging
- Dry run capability for request inspection

## Installation

This plugin is designed to be installed with [Lazy.nvim](https://github.com/folke/lazy.nvim).

Add the following to your Neovim configuration:

```lua
{
  "heilgar/nvim-http-client",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("http_client").setup({
      -- Optional: Configure default options here
      default_env_file = '.env.json',
      request_timeout = 30000, -- 30 seconds
    })
  end,
}
```

## Usage

1. Create a `.http` file with your HTTP requests.
2. Create a `.env.json` file with your environments.
3. Use the provided commands to select an environment and run requests.

### Example .http file

```
GET {{host}}/api/users

###

POST {{host}}/api/users
Content-Type: application/json

{
    "name": "John Doe",
    "email": "john@example.com"
}
```

### Example .env.json file

```json
{
    "*default": {
        "host": "http://localhost:3000"
    },
    "production": {
        "host": "https://api.example.com"
    }
}
```

## Commands

- `:HttpEnvFile`: Select an environment file (.env.json) to use.
- `:HttpEnv {env}`: Set the current environment to use (e.g., `:HttpEnv production`).
- `:HttpRun`: Run the HTTP request under the cursor.
- `:HttpStop`: Stop the currently running HTTP request.
- `:HttpVerbose`: Toggle verbose mode for debugging.
- `:HttpDryRun`: Perform a dry run of the request under the cursor.

## Keybindings

The plugin comes with the following default keybindings:

- `<leader>he`: Select environment file
- `<leader>hs`: Set current environment
- `<leader>hr`: Run HTTP request under cursor
- `<leader>hx`: Stop running HTTP request
- `<leader>hv`: Toggle verbose mode
- `<leader>hd`: Perform dry run

To customize these keybindings, you can add the following to your Neovim configuration:

```lua
{
    "heilgar/nvim-http-client",
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
    config = function()
        require("http_client").setup()
    end,
    event = "VeryLazy",
    keys = {
        { "<leader>he", "<cmd>HttpEnvFile<cr>", desc = "Select HTTP environment file" },
        { "<leader>hs", "<cmd>HttpEnv<cr>", desc = "Set HTTP environment" },
        { "<leader>hr", "<cmd>HttpRun<cr>", desc = "Run HTTP request" },
        { "<leader>hx", "<cmd>HttpStop<cr>", desc = "Stop HTTP request" },
        { "<leader>hv", "<cmd>HttpVerbose<cr>", desc = "Toggle verbose mode" },
        { "<leader>hd", "<cmd>HttpDryRun<cr>", desc = "Perform dry run" },
    },
    cmd = {
        "HttpEnvFile",
        "HttpEnv",
        "HttpRun",
        "HttpStop",
        "HttpVerbose",
        "HttpDryRun"
    },
}
```

You can change the key mappings by modifying the `keybindings` table in the setup function and updating the `keys` table accordingly.

## Documentation

After installing the plugin, you can access the full documentation by running `:h http_client` in Neovim.

## Environment Files

Environment files (.env.json) allow you to define different sets of variables for your HTTP requests. The plugin will look for these files in your project root directory.

The `*default` environment is used as a base, and other environments will override its values.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

