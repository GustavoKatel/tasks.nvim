local Task = require("tasks.lib.task")

local runner = {}

local function wrap_task_fn(fn)
	return function(_, args)
		fn(unpack(args or {}))
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
	end

	return task
end

return runner
