local fs = require("tasks.lib.fs")
local Source = require("tasks.lib.source")

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

    if type == "shell" then
        local default_shell = vim.env.SHELL or "bash"

        local shell = get_value("shell") or { executable = default_shell }

        local shell_cmd = table.concat(vim.tbl_flatten({ cmd, args }), " ")
        shell_cmd = string.format("'%s'", shell_cmd)

        cmd = { shell.executable or default_shell, shell.args, shell_cmd }
    else
        cmd = { cmd, args }
    end

    cmd = vim.tbl_flatten({ cmd })

    local dependencies = vim.tbl_map(
        function(spec_name)
            return { spec_name = spec_name }
        end,
        vim.tbl_filter(function(t)
            return t ~= nil
        end, vim.tbl_flatten({ json_task["dependsOn"] or {} }))
    )

    return label,
        {
            cmd = cmd,
            cwd = cwd,
            original = json_task,
            -- wrapping them in a single table, will make them run in parallel
            dependencies = { dependencies },
        }
end

return Source:create_from_source_file({
    filename = ".vscode/tasks.json",
    reader = fs.read_json_file,
    parser = function(_self, json)
        local specs = {}
        for i, json_task in ipairs(json.tasks or {}) do
            local label, spec = json_task_to_spec(i, json_task)
            spec.inputs = json.inputs
            specs[label] = spec
        end

        return specs
    end,
})
