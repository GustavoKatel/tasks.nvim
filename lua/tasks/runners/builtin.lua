local Task = require("tasks.lib.task")

local runner = {}

function runner:create_task(spec, args)
	local task

	if spec.fn ~= nil then
		task = Task:new(spec.fn, args)
	elseif spec.vcmd ~= nil then
		if args ~= nil then
			args = spec.vcmd .. " " .. args
		else
			args = spec.vcmd
		end
		task = Task:new(vim.cmd, { args })
	end

	return task
end

return runner
