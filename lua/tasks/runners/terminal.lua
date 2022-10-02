local pasync = require("tasks.lib.async")
local Task = require("tasks.lib.task")
local Runner = require("tasks.lib.runner")
local utils = require("tasks.utils")
local terminal = require("tasks.terminal")

local function wrap_task_terminal(self, spec, _runner_opts)
    return function(ctx, args)
        local tx, rx = pasync.control.channel.oneshot()

        local env = spec.env or {}

        local cmd = table.concat(utils.replace_variables_in_list({ spec.cmd, args }, spec), " ")

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
            ctx.wait_stop_requested()
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

local terminal_runner = Runner:create({
    sticky_terminal_window = false,

    sticky_termininal_window_number = nil,
})

function terminal_runner:can_handle_spec(_spec_name, spec)
    return spec.cmd ~= nil
end

function terminal_runner:create_task(spec, args, runner_opts)
    if spec.cmd == nil then
        error("terminal runner cannot handle this spec")
    end

    local task = Task:new(wrap_task_terminal(self, spec, runner_opts), args)

    return task
end

return terminal_runner
