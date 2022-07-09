local tasks_actions = require("telescope._extensions.tasks.actions")

local config = {}

local _Default = {
    mappings = {
        running = {
            i = {
                ["<c-c>"] = tasks_actions.request_stop,
            },
        },

        specs = {
            i = {
                ["<c-t>"] = tasks_actions.run_with_runner_opts({ terminal_edit_command = "vsplit" }),
            },
        },
    },
}

config.values = _Default

function config.setup(opts)
    -- TODO maybe merge other keys as well from telescope.config
    config.values.mappings =
        vim.tbl_deep_extend("force", {}, config.values.mappings or {}, require("telescope.config").values.mappings)
    config.values = vim.tbl_deep_extend("force", {}, config.values, opts)
end

function config.attach_mappings(picker_name, _prompt_bufnr, map)
    for mode, tbl in pairs(config.values.mappings[picker_name] or {}) do
        for key, action in pairs(tbl) do
            map(mode, key, action)
        end
    end
end

return config
