local M = {}

M.defaults = {
    default_env_file = '.env.json',
    request_timeout = 30000, -- 30 seconds
    split_direction = "right",
    keybindings = {
        select_env_file = "<leader>he",
        set_env = "<leader>hs",
        run_request = "<leader>hr",
        stop_request = "<leader>hx",
        dry_run = "<leader>hd",
        toggle_verbose = "<leader>hv"
    },
}

M.options = {}

function M.setup(opts)
    M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
end

function M.get(opt)
    return M.options[opt]
end

return M

