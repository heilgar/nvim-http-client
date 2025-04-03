# Autocompletion

nvim-http-client provides autocompletion for HTTP requests using two methods:

## Method 1: With nvim-cmp (Recommended)

For the best experience, [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) is recommended. The plugin will automatically detect and register completion sources with nvim-cmp if available.

With nvim-cmp, you'll get:
- Automatic suggestions as you type (LSP-like experience)
- HTTP methods completion at the start of a line
- HTTP headers completion with descriptions
- Environment variables completion when typing `{{`
- Content-Type values completion

To set up nvim-cmp with nvim-http-client:

1. Ensure you have nvim-cmp installed:
```lua
{
  "hrsh7th/nvim-cmp",
  -- and other nvim-cmp dependencies
}
```

2. The plugin will automatically register its completion sources when loaded. You can customize the configuration for HTTP files:

```lua
local cmp = require('cmp')
cmp.setup.filetype({ 'http', 'rest' }, {
  sources = cmp.config.sources({
    { name = 'http_method' },
    { name = 'http_header' },
    { name = 'http_env_var' },
    { name = 'buffer' },
  })
})
```

## Method 2: Traditional Vim Completion (Fallback)

If nvim-cmp is not available, the plugin will fall back to traditional Vim completion:

- Type `{{` to trigger environment variable completion
- Press `<Ctrl-X><Ctrl-O>` to manually trigger environment variable completion
- Press `<Ctrl-X><Ctrl-U>` to manually trigger HTTP methods and headers completion
- When pressing Enter on a new line, header completion will be automatically triggered

The fallback mode works well but lacks the smooth experience of nvim-cmp's automatic suggestions.

## Completion Features

The plugin provides the following completions:

### 1. HTTP Method Completion
- GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS, TRACE, CONNECT
- Each method includes documentation explaining its purpose
- Automatically triggered at the beginning of a line

### 2. HTTP Header Completion
- Common headers like Accept, Content-Type, Authorization, etc.
- Each header includes documentation
- Content-Type header provides additional MIME type completions
- Automatically triggered after method and URL

### 3. Environment Variable Completion
- Variables from the current environment file
- Global variables set through response handlers
- Recently used variables (cached)
- Documentation showing the variable type and current value
- Triggered when typing `{{`

### 4. Content Type Value Completion
- MIME types like application/json, application/xml, etc.
- Each with relevant documentation
- Triggered when typing a value for Content-Type header

## Troubleshooting

If you're experiencing issues with autocompletion:

1. Ensure nvim-cmp is properly installed and configured
2. Check that the plugin has loaded properly
3. Verify the file is recognized as `http` or `rest` filetype
4. Try using `:checkhealth http_client` to diagnose any issues 