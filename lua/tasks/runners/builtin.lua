local Task = require("tasks.lib.task")

local runner = {}

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
		task = Task:new(vim.cmd, { args })
	end

	return task
end

return runner
