# Changelog

All notable changes to this project will be documented in this file.


## 9/13/2024
### New Features
- Added support for private environment files (.private.env.json)
  - Private environment files are now automatically detected and loaded
  - Private environments take precedence over public environments

### Changes
- Updated environment handling mechanism
  - Improved merging of public and private environments
  - Default environments are now applied before specific environments
  - Private default environments override public default environments

### File Handling
- Modified file selection process to exclude private environment files from the overview
- Private environment file names now match their public counterparts
  - Example: .env.json -> .private.env.json
  - Example: http-client.env.json -> http-client.private.env.json

### Code Improvements
- Refactored environment.lua for better handling of public and private environment files
- Updated set_env_file function to set both current_env_file and current_private_env_file
- Modified set_env function to properly merge environments from both public and private files
- Added get_current_private_env_file function to retrieve the current private environment file path

### Security
- Improved handling of sensitive information by separating it into private environment files
- Private environment files are automatically excluded from git tracking (ensure .gitignore is updated)

### User Interface
- Updated Telescope integration to show merged environment preview (public + private)

### Note to Users
- To use private environments, create a .private.env.json file alongside your existing .env.json file
- Ensure your .gitignore includes *.private.env.json to prevent accidental commits of sensitive data

## Initial

### Added
- HTTP Request Parsing and Execution
  - Parse HTTP requests from .http files
  - Support for GET, POST, PUT, DELETE, PATCH, HEAD, and OPTIONS methods
  - Handle headers and request bodies
  - Execute requests using plenary.curl
- Environment Management
  - Support for multiple environments using .env.json files
  - Ability to switch between environments
  - Variable substitution in requests using {{variable}} syntax
- Response Handling
  - Display responses in a separate buffer
  - Format JSON and XML responses for better readability
  - Syntax highlighting for response content
- User Interface
  - Custom syntax highlighting for .http files
  - Custom syntax highlighting for response buffers
  - Split window configuration for displaying responses
- Commands
  - `:HttpEnvFile` - Select an environment file
  - `:HttpEnv` - Select an environment from the current file
  - `:HttpRun` - Execute the request under the cursor
  - `:HttpStop` - Stop the currently running request
  - `:HttpVerbose` - Toggle verbose mode for debugging
  - `:HttpDryRun` - Perform a dry run of the request without sending it
- Keybindings
  - Customizable keybindings for all major actions
  - Default keybindings provided out of the box
- Telescope Integration
  - Custom pickers for selecting environment files and environments
  - Preview window for environment contents
- Configuration
  - Customizable options for default environment file, request timeout, and split direction
  - Easy setup function for plugin configuration
- Debugging and Verbosity
  - Verbose mode for detailed logging of request and response information
  - Health checks to ensure proper plugin setup and dependencies
- Documentation
  - Help documentation accessible via `:help http_client`
  - Automatic generation of help tags

### Notes
- The plugin requires Neovim 0.5 or later
- Dependencies: plenary.nvim, telescope.nvim (optional for enhanced environment selection)

