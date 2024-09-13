# Working with a LazyVim Plugin Locally During Development

To work with a LazyVim plugin locally during development, follow these steps:

## 1. Clone the Plugin Locally

First, clone the plugin you want to develop into a local directory. For example:

```bash
git clone https://github.com/your-plugin-repo.git ~/path-to-local-plugin
```

## 2. Add the Local Plugin Path in `lazy.nvim` Setup

Edit your `lazy.nvim` configuration file (typically in `~/.config/nvim/lua/plugins.lua` or `~/.config/nvim/init.lua` if you are not using a modular structure).

Add the local plugin directory by using the `dev` key or specifying the path directly:

```lua
-- Example lazy.nvim setup
require("lazy").setup({
  {
    -- Path to the local plugin
    dir = "~/path-to-local-plugin",
    config = function()
      -- plugin setup if needed
    end
  }
})
```

Alternatively, you can specify it with the `dev` option to make it easier to switch between local development and a remote repository:

```lua
{
  "your-plugin-name",
  dev = true,
  dir = "~/path-to-local-plugin",
  config = function()
    -- plugin setup if needed
  end
}
```

## 3. Use LazyVim's Development Features

LazyVim can automatically load plugins from a local directory for easier development. This is helpful if you want to quickly reload or hot-reload changes. To enable this:

1. Open Neovim in the directory where the plugin is.
2. Run the following command to ensure the changes reflect:

```vim
:Lazynvim sync
```

This will reload the plugin configurations, and Neovim will use the local copy during development.

## 4. Edit and Test Changes

Make changes to the plugin code in the local directory, then open Neovim and test the plugin. You can use `:source %` to reload individual Lua files or restart Neovim for a full reload.

## 5. Debugging

To debug the plugin, you can use the following options:

* Use `print()` or `vim.inspect()` to inspect variables and values during plugin execution.
* LazyVim offers `:Lazy log` for checking plugin load and error logs.

## 6. Switch Back to Remote Plugin

Once you're done developing locally, you can easily switch back to the remote repository by removing or commenting out the `dir` entry from the `lazy.nvim` setup.

## Optional: Use `dev` Feature in Lazy.nvim

Lazy.nvim has a `dev` option to make plugin development easier. You can specify a local path for all plugins under a certain GitHub username:

```lua
require("lazy").setup({
  dev = {
    path = "~/path-to-local-plugins",
  },
})
```

In this case, all plugins in the `path` directory will be loaded from there for development.

