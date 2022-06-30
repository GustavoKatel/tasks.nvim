local Task = require("tasks.lib.task")

local M = {}

M.config = {
	-- Array<Source>
	sources = {},
	-- Array<Runner>
	runners = {
		builtin = require("tasks.runners.builtin"),
	},
}

M.state = {
	-- Array<TaskSpec>
	tasks = {},

	-- Array<Task>
	running_tasks = {},

	task_seq_nr = 1,
}

function M.setup(config)
	M.config = vim.tbl_extend("force", M.config, config or {})

	M.config.runners.builtin = require("tasks.runners.builtin")
end

function M._get_task_id()
	local id = M.state.task_seq_nr
	M.state.task_seq_nr = M.state.task_seq_nr + 1
	return id
end

function M.run(name, args)
	local spec

	for _, source_tasks in pairs(M.state.tasks) do
		if source_tasks[name] ~= nil then
			spec = source_tasks[name]
			break
		end
	end

	if spec == nil then
		vim.notify("task not found", vim.log.levels.WARN)
		return
	end

	local runner = M.config.runners[spec.runner or "builtin"]

	local task = runner:create_task(spec, args)
	local task_id = M._get_task_id()

	M.state.running_tasks[task_id] = task

	task:on_finish(function()
		M.state.running_tasks[task_id] = nil
	end)

	task:run()

	return task_id
end

function M.reload_tasks()
	-- PERF: should run all using plenary.run_all?
	for name, source in pairs(M.config.sources) do
		M.state.tasks[name] = source:get_tasks()
	end
end

local function filter_tasks(opts, tbl)
	opts = vim.tbl_deep_extend("force", { source = nil }, opts or {})

	local result = vim.tbl_filter(function(task)
		local match_source = opts.source == nil or opts.source == task.source
		local match_runner = opts.runner == nil or opts.runner == task.runner

		return match_source or match_runner
	end, tbl)

	return result
end

-- @param table opts
-- @param
function M.get_tasks(opts)
	return filter_tasks(opts, M.state.tasks)
end

function M.get_running_tasks(opts)
	return filter_tasks(opts, M.state.running_tasks)
end

return M
