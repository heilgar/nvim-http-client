# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] 2024-09-17
### Added
- New feature: Generate and display curl command in dry run output
- New command: `:HttpCopyCurl` to copy curl command for the request under cursor
- New keybinding: `<leader>hc` to copy curl command
- Support for comments in .http and .rest files
    - Full line comments starting with '#'
    - Inline comments from '#' to end of line


## [1.0.0] 2024-09-17
### Added
- Comprehensive test suite
    - Test created for parser, utils, init, config and health
- Command to run tests
- Workflow to run tests
### Updated
- CONTRIBUTING.md

## [1.0.0] 2024-09-16
### New Features
- Initial support for response handler scripts
  - Ability to execute `client.global.set(k, v)`
  - Set global variables based on response data
- Global variables functionality
  - Set and use variables that persist across requests within a session
  - Global variables take precedence over environment variables
- New command `:HttpRunAll` to run all requests in the current file
### Changes
- Updated request execution to work without selecting an environment file
- Improved dry run functionality to execute even when no environment file is selected
### Improvements
- Added warning message when environment variables are needed but not set
### Code Improvements
- Refactored command structure for better organization:
  - Split commands into separate files: `request.lua`, `select_env.lua`
  - Created a new `commands/init.lua` to manage command modules
- Updated `init.lua` to use the new command structure

## [1.0.0] - 2024-09-13
### New Features
- Added support for private environment files (.private.env.json)
  - Private environment files are now automatically detected and loaded
  - Private environments take precedence over public environments
- Implemented HTTP version support
  - Added ability to specify HTTP/1.1 and HTTP/2 in requests
  - HTTP/2 (Prior Knowledge) support added for servers that can handle HTTP/2 connections without upgrades
- Introduced SSL configuration options
  - Added ability to disable certificate verification for development environments
### Changes
- Updated environment handling mechanism
  - Improved merging of public and private environments
  - Default environments are now applied before specific environments
  - Private default environments override public default environments
- Modified HTTP request parsing to handle requests with and without explicit HTTP versions
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
- Refactored parser.lua to correctly handle HTTP version in request parsing
- Updated http_client.lua to support different HTTP versions and SSL configurations
### Code Restructuring
- Reorganized project structure for improved maintainability
  - Created `core` directory for main plugin logic
    - Moved `parser.lua`, `http_client.lua`, and `environment.lua` into `core`
  - Created `utils` directory for utility functions
    - Moved `file_utils.lua` and `verbose.lua` into `utils`
  - Created `ui` directory for user interface related code
    - Renamed `ui.lua` to `display.lua` and moved it to `ui`
    - Moved `dry_run.lua` into `ui`
  - Created new `config.lua` file for centralized configuration management
- Updated import statements across the project to reflect new file structure
- Improved modularity and logical grouping of related functionalities
### Security
- Improved handling of sensitive information by separating it into private environment files
- Private environment files are automatically excluded from git tracking (ensure .gitignore is updated)
- Added option to disable SSL certificate verification for trusted development environments
### User Interface
- Updated Telescope integration to show merged environment preview (public + private)
- Added dry run support for HTTP version display
### Documentation
- Updated documentation to include information on HTTP version support and SSL configuration options
### Note to Users
- Ensure your .gitignore includes *.private.env.json to prevent accidental commits of sensitive data
- To use private environments, create a .private.env.json file alongside your existing .env.json file
- When using self-signed certificates in development, you can now disable certificate verification in your environment configuration

## [1.0.0]

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

