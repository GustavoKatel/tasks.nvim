local tasks = require("tasks")

local M = {}

function M.tasks_setup(config)
    tasks.state.specs = {}
    tasks.state.running_tasks = {}
    tasks.state.last_spec_ran = nil

    tasks.setup(config)
end

return M
