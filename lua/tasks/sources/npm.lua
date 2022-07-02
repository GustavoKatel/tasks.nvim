local Path = require("plenary.path")
local fs = require("tasks.lib.fs")

local M = {}

function M:get_specs()
	local path = Path:new(vim.loop.cwd()) / "package.json"

	local ok, package = pcall(fs.read_json_file, path.filename)
	if not ok then
		return nil
	end

	local tasks = {}

	local scripts = package["scripts"] or {}

	for name, cmd in pairs(scripts) do
		tasks[name] = {
			cmd = cmd,
			cwd = vim.loop.cwd(),
		}
	end

	return tasks
end

function M:start_specs_listener(tx) end

return M
