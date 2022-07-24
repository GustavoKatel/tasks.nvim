local pasync = require("tasks.lib.async")
local Task = require("tasks.lib.task")
local Runner = require("tasks.lib.runner")
local utils = require("tasks.utils")

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

local function wrap_task_terminal(self, spec, runner_opts)
    runner_opts = runner_opts or {}

    return function(ctx, args)
        local tx, rx = pasync.control.channel.oneshot()

        args = replace_variables(args, spec)

        local env = spec.env or {}

        local env_concat = table.concat(
            vim.tbl_map(function(env_name)
                return env_name .. "=" .. env[env_name]
            end, vim.tbl_keys(env)),
            " "
        )

        if env_concat ~= "" then
            env_concat = env_concat .. " "
        end

        local cmd = table.concat(replace_variables({ env_concat, spec.cmd, args }, spec), " ")

        local edit_cmd = runner_opts.terminal_edit_command or self.terminal_edit_command or "edit"

        cmd = edit_cmd .. " term://" .. (spec.cwd or vim.loop.cwd()) .. "//" .. cmd

        local current_window_nr = vim.api.nvim_win_get_number(vim.api.nvim_get_current_win())
        if self.sticky_terminal_window then
            if
                self.sticky_termininal_window_number ~= nil
                and self.sticky_termininal_window_number ~= current_window_nr
            then
                vim.cmd(self.sticky_termininal_window_number .. "wincmd w")
            end

            if self.sticky_termininal_window_number == nil then
                self.sticky_termininal_window_number = current_window_nr
            end
        end

        vim.cmd(cmd)

        local buffer = vim.api.nvim_get_current_buf()
        local term_id = vim.b.terminal_job_id

        ctx.metadata.buffer = buffer
        ctx.metadata.term_id = term_id

        pasync.run(function()
            ctx.stop_request_receiver()
            vim.fn.jobstop(term_id)
        end)

        vim.api.nvim_buf_set_option(buffer, "bufhidden", "hide")

        vim.api.nvim_create_autocmd({ "TermClose" }, {
            buffer = buffer,
            callback = function(event)
                tx(event)
            end,
        })

        if self.sticky_terminal_window then
            if current_window_nr ~= self.sticky_termininal_window_number then
                vim.cmd("wincmd p")
            end
        end

        rx()
    end
end

local builtin = Runner:create({
    sticky_terminal_window = false,

    sticky_termininal_window_number = nil,

    terminal_edit_command = "edit",
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
