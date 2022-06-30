local Task = {}

function Task:new(async_fn, args)
	local t = { fn = async_fn, args }
	setmetatable(t, self)
	self.__index = self
	return t
end

function Task:run()
	return self.fn(unpack(self.args or {}))
end

return Task
