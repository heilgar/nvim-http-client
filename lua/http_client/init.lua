local M = {}

M.config = require("http_client.config")

local function setup_docs()
	if vim.fn.has("nvim-0.7") == 1 then
		vim.api.nvim_create_autocmd("BufWinEnter", {
			group = vim.api.nvim_create_augroup("http_client_docs", {}),
			pattern = "*/http_client/doc/*.txt",
			callback = function()
				vim.cmd("silent! helptags " .. vim.fn.expand("%:p:h"))
			end,
		})
	end
end

local function set_keybindings()
	if M.config.get("create_keybindings") then
		local opts = { noremap = true, silent = true }
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "http",
			callback = function()
				vim.keymap.set("n", M.config.get("keybindings").select_env_file, ":HttpEnvFile<CR>", opts)
				vim.keymap.set(
					"n",
					M.config.get("keybindings").set_env,
					":HttpEnv<CR>",
					{ noremap = true, buffer = true }
				)
				vim.keymap.set("n", M.config.get("keybindings").run_request, ":HttpRun<CR>", opts)
				vim.keymap.set("n", M.config.get("keybindings").stop_request, ":HttpStop<CR>", opts)
				vim.keymap.set("n", M.config.get("keybindings").dry_run, ":HttpDryRun<CR>", opts)
				vim.keymap.set("n", M.config.get("keybindings").toggle_verbose, ":HttpVerbose<CR>", opts)
				vim.keymap.set("n", M.config.get("keybindings").copy_curl, ":HttpCopyCurl<CR>", opts)
			end,
		})
	end
end

M.setup = function(opts)
	M.config.setup(opts)

	-- Load all necessary modules
	M.environment = require("http_client.core.environment")
	M.file_utils = require("http_client.utils.file_utils")
	M.http_client = require("http_client.core.http_client")
	M.parser = require("http_client.core.parser")
	M.ui = require("http_client.ui.display")
	M.dry_run = require("http_client.ui.dry_run")
	M.v = require("http_client.utils.verbose")
	M.commands = require("http_client.commands")

	-- Set up commands
	vim.api.nvim_create_user_command("HttpEnvFile", function()
		M.commands.select_env.select_env_file(M.config.get())
	end, {
		desc = "Select an environment file for HTTP requests.",
	})

	vim.api.nvim_create_user_command("HttpEnv", function()
		M.commands.select_env.select_env()
	end, {
		desc = "Select an environment for HTTP request (requires one argument).",
	})

	vim.api.nvim_create_user_command("HttpRun", function()
		M.commands.request.run_request()
	end, {
		desc = "Run the HTTP request under cursor. Use ! to enable verbose mode.",
	})

	vim.api.nvim_create_user_command("HttpRunAll", function()
		M.commands.request.run_all()
	end, {
		desc = "Run all HTTP requests in the current file.",
	})

	vim.api.nvim_create_user_command("HttpStop", function()
		M.commands.request.stop_request()
	end, {
		desc = "Stop the currently running HTTP request.",
	})

	vim.api.nvim_create_user_command("HttpVerbose", function()
		local current_state = M.v.get_verbose_mode()
		M.v.set_verbose_mode(not current_state)
		print(string.format("HTTP Client verbose mode %s", not current_state and "enabled" or "disabled"))
	end, {
		desc = "Toggle verbose mode for HTTP request.",
	})

	vim.api.nvim_create_user_command("HttpDryRun", function()
		M.dry_run.display_dry_run(M)
	end, {
		desc = "Perform a dry run of the HTTP request without sending it.",
	})

	vim.api.nvim_create_user_command("HttpCopyCurl", function()
		M.commands.utils.copy_curl()
	end, {
		desc = "Copy curl command for the HTTP request under cursor.",
	})

	setup_docs()
	set_keybindings()

	M.health = require("http_client.health")
	-- Register health check
	local health = vim.health or M.health
	if health.register then
		-- Register the health check with the new API
		health.register("http_client", M.health.check)
	else
		-- Fallback for older Neovim versions
		vim.api.nvim_create_autocmd("VimEnter", {
			callback = function()
				M.health.check()
			end,
		})
	end
end

return M
