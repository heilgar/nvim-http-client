local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

local http_client = require("http_client")

local http_envs

local function select_env(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    actions.close(prompt_bufnr)
    http_client.environment.set_env(selection.value)
end

local function env_previewer()
    return previewers.new_buffer_previewer({
        title = "Environment Preview",
        get_buffer_by_name = function(_, entry)
            return entry.value
        end,
        define_preview = function(self, entry, status)
            local env_file = http_client.environment.get_current_env_file()
            local env_data = http_client.file_utils.read_json_file(env_file)
            local env_content = vim.inspect(env_data[entry.value] or {})
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(env_content, '\n'))
            vim.api.nvim_buf_set_option(self.state.bufnr, 'filetype', 'lua')
        end,
    })
end

http_envs = function(opts)
    opts = opts or {}
    local env_file = http_client.environment.get_current_env_file()
    if not env_file then
        print("No environment file selected. Please select an environment file first.")
        return
    end

    local env_data = http_client.file_utils.read_json_file(env_file)
    if not env_data then
        print("Failed to read environment file")
        return
    end

    local results = { "*default" }
    for name, _ in pairs(env_data) do
        if name ~= "*default" then
            table.insert(results, name)
        end
    end

    pickers.new(opts, {
        prompt_title = "HTTP Environments",
        finder = finders.new_table {
            results = results,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = entry,
                    ordinal = entry,
                }
            end
        },
        sorter = conf.generic_sorter(opts),
        previewer = env_previewer(),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                select_env(prompt_bufnr)
            end)
            return true
        end,
    }):find()
end

local function select_env_file(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    actions.close(prompt_bufnr)
    http_client.environment.set_env_file(selection.value)
    -- Automatically open env selection after file selection
    vim.defer_fn(function()
        http_envs()
    end, 10)
end

local http_env_files = function(opts)
    opts = opts or {}
    local results = http_client.file_utils.find_files('*.env.json')

    pickers.new(opts, {
        prompt_title = "HTTP Environment Files",
        finder = finders.new_table {
            results = results,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = entry,
                    ordinal = entry,
                }
            end
        },
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                select_env_file(prompt_bufnr)
            end)
            return true
        end,
    }):find()
end

local function health_check()
    local health = vim.health or require("htt_client.health")
    health.start("Telescope Extension: `http_client`")
    health.ok("Telescope HTTP Client extension is available")
end

return require("telescope").register_extension {
    exports = {
        http_env_files = http_env_files,
        http_envs = http_envs,
    },
    health = health_check
}

