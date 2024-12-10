local M = {}

M.defaults = {
	default_env_file = ".env.json",
	request_timeout = 30000, -- 30 seconds
	split_direction = "right",
	create_keybindings = true,
	keybindings = {
		select_env_file = "<leader>he",
		set_env = "<leader>hs",
		run_request = "<leader>hr",
		stop_request = "<leader>hx",
		dry_run = "<leader>hd",
		toggle_verbose = "<leader>hv",
		copy_curl = "<leader>hc",
	},
}

M.options = {}

function M.setup(opts)
	opts = opts or {}
	M.options = vim.tbl_deep_extend("force", M.defaults, opts) or M.defaults
end

function M.get(opt)
	return M.options[opt]
end

return M
