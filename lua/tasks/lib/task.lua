local pasync = require("plenary.async")
local task_state = require("tasks.lib.task_state")
local CancelToken = require("tasks.lib.cancel_token")

local _next_id = 1

local Task = {}

local function create_task_context(task)
    return {
        wait_stop_requested = function()
            task.cancel_token:wait()
        end,
        metadata = task.metadata,
        id = task:get_id(),
    }
end

function Task:new(async_fn, args, opts)
    opts = opts or {}

    local id = _next_id
    _next_id = _next_id + 1

    local t = {
        id = id,
        fn = async_fn,
        args = args,
        metadata = { spec = nil, spec_name = nil, source_name = nil, runner_name = nil },
        state = task_state.READY,
        events = {},
        started_time = nil,
        finished_time = nil,

        ctx = nil,

        cancel_token = CancelToken:new(opts.cancel_token),
    }

    setmetatable(t, self)
    self.__index = self
    return t
end

function Task:set_metadata(metadata)
    self.metadata = metadata
end

function Task:get_spec_name()
    if self.metadata == nil then
        return nil
    end

    return self.metadata.spec_name
end

function Task:get_spec()
    if self.metadata == nil then
        return nil
    end

    return self.metadata.spec
end

function Task:get_source_name()
    if self.metadata == nil then
        return nil
    end

    return self.metadata.source_name
end

function Task:get_runner_name()
    if self.metadata == nil then
        return nil
    end

    return self.metadata.runner_name
end

function Task:get_id()
    return self.id
end

function Task:run()
    self.state = task_state.RUNNING
    self.started_time = vim.loop.hrtime()

    self.ctx = create_task_context(self)

    pasync.run(function()
        self.fn(self.ctx, self.args)
    end, function()
        if self.cancel_token:is_cancelled() then
            self.state = task_state.CANCELLED
        else
            self.state = task_state.DONE
        end
        self.finished_time = vim.loop.hrtime()
        self:dispatch_event("finish")
    end)
end

function Task:get_state()
    return self.state
end

function Task:on_finish(fn)
    self.events["finish"] = self.events["finish"] or {}

    table.insert(self.events["finish"], fn)
end

function Task:dispatch_event(event_name, args)
    local events = self.events[event_name] or {}

    for _, fn in ipairs(events) do
        fn(args)
    end
end

function Task:request_stop()
    self.cancel_token:cancel()
end

function Task:get_started_time()
    return self.started_time
end

function Task:get_finished_time()
    return self.finished_time
end

return Task
