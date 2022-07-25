local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local tasks = require("tasks")

local M = {}

function M.run(prompt_bufnr)
    actions.close(prompt_bufnr)
    local selection = action_state.get_selected_entry()

    local entry = selection.value

    tasks.run(entry.spec_name, nil, entry.source_name)
end

function M.run_with_runner_opts(runner_opts)
    return function(prompt_bufnr)
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()

        local entry = selection.value

        tasks.run(entry.spec_name, nil, entry.source_name, runner_opts)
    end
end

function M.request_stop(prompt_bufnr)
    actions.close(prompt_bufnr)
    local selection = action_state.get_selected_entry()

    local task = selection.value.task

    task:request_stop()
end

function M.open_buffer(opts)
    opts = vim.tbl_extend("force", { cmd = "buffer" }, opts or {})

    return function(prompt_bufnr)
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()

        local task = selection.value.task

        assert(task.metadata.buffer ~= nil, "task doesn't have a buffer attached")

        local cmd = table.concat(vim.tbl_flatten({ opts.cmd, task.metadata.buffer }), " ")
        vim.cmd(cmd)
    end
end

return M
