local Runner = require("tasks.lib.runner")
local Task = require("tasks.lib.task")
local utils = require("tasks.utils")

local function wrap_task_fn(fn, spec)
    return function(_, args)
        fn(unpack(utils.replace_variables_in_list(args or {}, spec)))
    end
end

local vim_cmd_runner = Runner:create()

function vim_cmd_runner:can_handle_spec(_spec_name, spec)
    return spec.vim_cmd ~= nil
end

function vim_cmd_runner:create_task(spec, args, _runner_opts)
    if spec.vim_cmd == nil then
        error("vim_cmd runner cannot handle this spec")
    end

    local vim_cmd

    if type(spec.vim_cmd) == "table" then
        vim_cmd = table.concat(spec.vim_cmd, " ")
    else
        vim_cmd = spec.vim_cmd
    end

    if args ~= nil then
        args = vim_cmd .. " " .. args
    else
        args = vim_cmd
    end

    local task = Task:new(wrap_task_fn(vim.cmd, spec), { args })

    return task
end

return vim_cmd_runner
