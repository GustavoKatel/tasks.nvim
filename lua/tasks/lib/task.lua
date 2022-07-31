local pasync = require("plenary.async")

local _next_id = 1

local Task = {}

local function create_task_context(task)
    return { stop_request_receiver = task.stop_rx, metadata = task.metadata, id = task:get_id() }
end

function Task:new(async_fn, args)
    local id = _next_id
    _next_id = _next_id + 1

    local t = {
        id = id,
        fn = async_fn,
        args = args,
        metadata = { spec = nil, spec_name = nil, source_name = nil, runner_name = nil },
        state = "ready",
        events = {},
        started_time = nil,
        finished_time = nil,

        ctx = nil,
    }

    local stop_tx, stop_rx = pasync.control.channel.oneshot()

    t.stop_tx = stop_tx
    t.stop_rx = stop_rx

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
    self.state = "running"
    self.started_time = vim.loop.hrtime()

    self.ctx = create_task_context(self)

    pasync.run(function()
        self.fn(self.ctx, self.args)
    end, function()
        self.state = "done"
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
    self.stop_tx()
end

function Task:get_started_time()
    return self.started_time
end

function Task:get_finished_time()
    return self.finished_time
end

return Task
