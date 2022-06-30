local pasync = require("plenary.async")

local Task = {}

function Task:new(async_fn, args)
	local t = { fn = async_fn, args = args, state = "ready" }
	setmetatable(t, self)
	self.__index = self
	return t
end

function Task:run()
	self.state = "running"

	pasync.run(function()
		self.fn(unpack(self.args or {}))
	end, function()
		self.state = "done"
	end)
end

function Task:get_state()
	return self.state
end

return Task
