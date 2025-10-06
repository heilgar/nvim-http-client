local M = {}

M.defaults = {
    default_env_file = ".env.json",
    request_timeout = 30000, -- 30 seconds
    split_direction = "right",
    create_keybindings = true,
    user_agent = "heilgar/nvim-http-client", -- Default User-Agent header
    profiling = {
        enabled = true,
        show_in_response = true,
        detailed_metrics = true,
    },
    keybindings = {
        select_env_file = "<leader>hf",
        set_env = "<leader>he",
        run_request = "<leader>hr",
        stop_request = "<leader>hx",
        dry_run = "<leader>hd",
        toggle_verbose = "<leader>hv",
        copy_curl = "<leader>hc",
        save_response = "<leader>hs",
        toggle_profiling = "<leader>hp",
        set_project_root = "<leader>hg",
        get_project_root = "<leader>hgg",
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

