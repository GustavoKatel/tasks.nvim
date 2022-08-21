local pasync = require("tasks.lib.async")
local Task = require("tasks.lib.task")
local Runner = require("tasks.lib.runner")
local utils = require("tasks.utils")
local terminal = require("tasks.terminal")

local function replace_variables(list, spec)
    return vim.tbl_map(function(item)
        return utils.replace_variables(item, spec.inputs)
    end, vim.tbl_flatten({ list }))
end

local function wrap_task_fn(fn, spec)
    return function(_, args)
        fn(unpack(replace_variables(args or {}, spec)))
    end
end

local function wrap_task_terminal(self, spec, _runner_opts)
    return function(ctx, args)
        local tx, rx = pasync.control.channel.oneshot()

        args = replace_variables(args, spec)

        local env = spec.env or {}

        local cmd = table.concat(replace_variables({ spec.cmd, args }, spec), " ")

        local current_window_nr = vim.api.nvim_get_current_win()

        if self.sticky_terminal_window then
            if
                self.sticky_termininal_window_number ~= nil
                and self.sticky_termininal_window_number ~= current_window_nr
            then
                pasync.api.nvim_set_current_win(self.sticky_termininal_window_number)
            end

            if self.sticky_termininal_window_number == nil then
                self.sticky_termininal_window_number = current_window_nr
            end
        end

        local terminal_job = terminal.create_terminal_job(self.sticky_termininal_window_number, cmd, {
            env = env,
            cwd = spec.cwd,
            buf_name = string.format("%s [%s] [id:%d]", ctx.metadata.spec_name, ctx.metadata.source_name, ctx.id),
            on_exit = function(_, code)
                tx(code)
            end,
        })

        ctx.metadata.buffer = terminal_job.bufnr
        ctx.metadata.job_id = terminal_job.job_id

        pasync.run(function()
            ctx.stop_request_receiver()
            vim.fn.jobstop(terminal_job.job_id)
        end)

        if self.sticky_terminal_window then
            if current_window_nr ~= self.sticky_termininal_window_number then
                pasync.api.nvim_set_current_win(current_window_nr)
            end
        end

        rx()
    end
end

local builtin = Runner:create({
    sticky_terminal_window = false,

    sticky_termininal_window_number = nil,
})

function builtin:create_task(spec, args, runner_opts)
    local task

    if spec.fn ~= nil then
        task = Task:new(spec.fn, args)
    elseif spec.vim_cmd ~= nil then
        if type(spec.vim_cmd) == "table" then
            spec.vim_cmd = table.concat(spec.vim_cmd, " ")
        end

        if args ~= nil then
            args = spec.vim_cmd .. " " .. args
        else
            args = spec.vim_cmd
        end
        task = Task:new(wrap_task_fn(vim.cmd, spec), { args })
    elseif spec.cmd ~= nil then
        task = Task:new(wrap_task_terminal(self, spec, runner_opts), args)
    else
        error("invalid task spec")
    end

    return task
end

return builtin
