local pasync = require("plenary.async")

local Task = {}

function Task:new(async_fn, args)
	local t = { fn = async_fn, args = args, state = "ready", events = {} }

	local stop_tx, stop_rx = pasync.control.channel.oneshot()

	t.stop_tx = stop_tx
	t.stop_rx = stop_rx

	setmetatable(t, self)
	self.__index = self
	return t
end

local function create_task_context(task)
	return { stop_request_receiver = task.stop_rx }
end

function Task:run()
	self.state = "running"

	pasync.run(function()
		self.fn(create_task_context(self), self.args)
	end, function()
		self.state = "done"
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

return Task
