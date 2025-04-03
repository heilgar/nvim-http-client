# Telescope Integration

nvim-http-client integrates with [Telescope](https://github.com/nvim-telescope/telescope.nvim) to provide a more interactive and visual way to select environment files and environments.

## Setup

To use the Telescope integration:

1. Make sure you have Telescope installed and configured:

```lua
{
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" }
}
```

2. Load the extension in your Neovim configuration:

```lua
require('telescope').load_extension('http_client')
```

This can be added to your plugin setup:

```lua
config = function()
    require("http_client").setup({
        -- your configuration
    })
    
    if pcall(require, "telescope") then
        require("telescope").load_extension("http_client")
    end
end
```

## Commands

The plugin adds the following Telescope commands:

- `:Telescope http_client http_env_files`: Browse and select HTTP environment files
- `:Telescope http_client http_envs`: Browse and select HTTP environments from the current environment file

## Keybindings

You can create keybindings for these commands in your configuration:

```lua
-- With lazy.nvim
keys = {
    { "<leader>hf", "<cmd>Telescope http_client http_env_files<cr>", desc = "Select HTTP env file (Telescope)" },
    { "<leader>hh", "<cmd>Telescope http_client http_envs<cr>", desc = "Select HTTP env (Telescope)" },
}

-- Or with direct keymaps
vim.api.nvim_set_keymap('n', '<leader>hf', [[<cmd>Telescope http_client http_env_files<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>he', [[<cmd>Telescope http_client http_envs<CR>]], { noremap = true, silent = true })
```

## Usage Flow

1. Use `http_env_files` to first select which environment file you want to use (e.g., `.env.json`)
2. Then use `http_envs` to select the specific environment within that file (e.g., `production`, `staging`, etc.)

Note: You need to select an environment file using `http_env_files` before you can select an environment using `http_envs`.

## Features

- Visual selection of environment files
- Preview of environment file contents
- Visual selection of environments within a file
- Preview of environment variables in each environment
- Seamless integration with the Telescope UI 