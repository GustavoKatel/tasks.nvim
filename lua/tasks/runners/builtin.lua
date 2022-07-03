local pasync = require("plenary.async")
local Task = require("tasks.lib.task")

local runner = {}

local function wrap_task_fn(fn)
    return function(_, args)
        fn(unpack(args or {}))
    end
end

local function wrap_task_terminal(spec)
    return function(ctx)
        local tx, rx = pasync.control.channel.oneshot()

        local cmd = table.concat(vim.tbl_flatten({ spec.cmd }), " ")

        cmd = "edit term://" .. (spec.cwd or vim.loop.cwd()) .. "//" .. cmd

        vim.cmd(cmd)

        local buffer = vim.api.nvim_get_current_buf()
        local term_id = vim.b.terminal_job_id

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

        rx()
    end
end

function runner:create_task(spec, args)
    local task

    if spec.fn ~= nil then
        task = Task:new(spec.fn, args)
    elseif spec.vim_cmd ~= nil then
        if args ~= nil then
            args = spec.vim_cmd .. " " .. args
        else
            args = spec.vim_cmd
        end
        task = Task:new(wrap_task_fn(vim.cmd), { args })
    elseif spec.cmd ~= nil then
        task = Task:new(wrap_task_terminal(spec), nil)
    end

    return task
end

return runner
