local Path = require("plenary.path")
local fs = require("tasks.lib.fs")
local async = require("tasks.lib.async")

local M = {}

function M:get_specs(tx)
    local path = Path:new(vim.loop.cwd()) / "package.json"

    local ok, package = pcall(fs.read_json_file, path.filename)
    if not ok then
        return nil
    end

    local specs = {}

    local scripts = package["scripts"] or {}

    for name, cmd in pairs(scripts) do
        specs[name] = {
            cmd = cmd,
            cwd = vim.loop.cwd(),
        }
    end

    if tx ~= nil then
        tx(specs)
    end

    return specs
end

function M:start_specs_listener(tx)
    local group_name = "TasksNvimNpmSource"
    vim.api.nvim_create_augroup(group_name, {
        clear = true,
    })

    vim.api.nvim_create_autocmd("BufWritePost", {
        group = group_name,
        pattern = { "package.json" },
        callback = function()
            async.run(function()
                M:get_specs(tx)
            end)
        end,
    })
end

return M
