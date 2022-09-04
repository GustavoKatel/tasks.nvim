local Runner = require("tasks.lib.runner")
local Task = require("tasks.lib.task")

local functions_runner = Runner:create()

function functions_runner:can_handle_spec(_spec_name, spec)
    return spec.fn ~= nil
end

function functions_runner:create_task(spec, args, _runner_opts)
    if spec.fn == nil then
        error("functions runner cannot handle this spec")
    end

    local task = Task:new(spec.fn, args)

    return task
end

return functions_runner
