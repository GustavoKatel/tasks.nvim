local Path = require("plenary.path")
local fs = require("tasks.lib.fs")
local async = require("tasks.lib.async")

local M = {}

local os_name_map = {
    ["Darwin"] = "osx",
    ["Linux"] = "linux",
    ["Windows"] = "windows",
}

local function get_task_label(root_label, json_task)
    local label = root_label

    local label_from_group = {
        ["build"] = "Build",
        ["test"] = "Test",
    }

    if label == nil or label == "" then
        local group = json_task.group or {}
        label = label_from_group[group] or label_from_group[group.kind]
    end

    return label
end

local function parse_args(args)
    return vim.tbl_map(function(arg)
        if type(arg) == "table" then
            -- TODO: quoting
            return arg.value
        end

        return arg
    end, args or {})
end

local function json_task_to_spec(index, json_task)
    local os_name = os_name_map[vim.loop.os_uname().sysname]
    local os_overrides = json_task[os_name] or {}

    local function get_value(key_name)
        return os_overrides[key_name] or json_task[key_name]
    end

    local label = get_task_label(get_value("label"), json_task)
    local cmd = get_value("command")
    local args = parse_args(get_value("args"))
    local type = get_value("type")
    local cwd = get_value("cwd")

    if type == "npm" then
        cmd = { "npm", "run" }
        args = { get_value("script") }
    end

    if type == "typescript" then
        cmd = { "tsc" }
        args = { args, "--project", (get_value("tsconfig") or "tsconfig.json") }
    end

    if label == "" or label == nil then
        label = string.format("task %d", index)
    end

    -- TODO: task dependencies
    -- TODO: env

    if type == "shell" then
        local shell = get_value("shell") or { executable = vim.env.SHELL }

        local shell_cmd = table.concat(vim.tbl_flatten({ cmd, args }), " ")
        shell_cmd = string.format("'%s'", shell_cmd)

        cmd = { shell.executable or vim.env.SHELL, shell.args, shell_cmd }
    else
        cmd = { cmd, args }
    end

    return label, {
        cmd = vim.tbl_flatten(cmd),
        cwd = cwd,
        original = json_task,
    }
end

-- TODO: parse tasks.json variables
function M:get_specs(tx)
    local path = Path:new(vim.loop.cwd()) / ".vscode" / "tasks.json"

    local ok, json = pcall(fs.read_json_file, path.filename)
    if not ok then
        return nil
    end

    local specs = {}

    for i, json_task in ipairs(json.tasks or {}) do
        local label, spec = json_task_to_spec(i, json_task)
        specs[label] = spec
    end

    if tx ~= nil then
        tx(specs)
    end

    return specs
end

function M:start_specs_listener(tx)
    local group_name = "TasksNvimTasksJsonSource"
    vim.api.nvim_create_augroup(group_name, {
        clear = true,
    })

    vim.api.nvim_create_autocmd("BufWritePost", {
        group = group_name,
        pattern = { ".vscode/tasks.json" },
        callback = function()
            async.run(function()
                M:get_specs(tx)
            end)
        end,
    })
end

return M
