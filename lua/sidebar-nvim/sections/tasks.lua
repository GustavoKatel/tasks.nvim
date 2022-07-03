local Loclist = require("sidebar-nvim.components.loclist")
local tasks = require("tasks")

local loclist = Loclist:new({ omit_single_group = true })

local task_state_icons = {
    ["running"] = "",
    ["done"] = "",
}

local function get_task_duration(task)
    local started_time = task:get_started_time()
    local finished_time = task:get_finished_time() or vim.loop.hrtime()

    local duration_ns = finished_time - started_time

    return string.format("%.1f", duration_ns / 1000000000) .. "s"
end

local function get_running_tasks(ctx)
    local lines = {}
    local hl = {}

    local running_tasks = tasks.get_running_tasks()

    local loclist_items = vim.tbl_map(function(task_id)
        local task = running_tasks[task_id]

        return {
            group = "tasks",
            left = {
                { text = task_state_icons[task:get_state()], hl = "SidebarNvimTasksState" },
                { text = "  " },
                { text = task:get_spec_name(), hl = "SidebarNvimTasksNormal" },
                { text = "  " },
                { text = task:get_source_name(), hl = "SidebarNvimTasksSource" },
                { text = "  id:", hl = "SidebarNvimTasksId" },
                { text = task_id, hl = "SidebarNvimTasksId" },
            },
            right = {
                { text = get_task_duration(task), hl = "SidebarNvimTasksDuration" },
            },
            data = {
                task = task,
            },
            order = task:get_spec_name(),
        }
    end, vim.tbl_keys(running_tasks))

    loclist:set_items(loclist_items, { remove_groups = false })

    loclist:draw(ctx, lines, hl)

    if lines == nil or #lines == 0 then
        return "<no tasks>"
    else
        return { lines = lines, hl = hl }
    end
end

return {
    title = "Tasks",
    icon = "",
    draw = get_running_tasks,
    highlights = {
        groups = {},
        links = {
            SidebarNvimTasksNormal = "SidebarNvimNormal",
            SidebarNvimTasksSource = "SIdebarNvimComment",
            SidebarNvimTasksState = "SIdebarNvimLabel",
            SidebarNvimTasksDuration = "SIdebarNvimLineNr",
            SidebarNvimTasksId = "SIdebarNvimLineNr",
        },
    },
    bindings = {
        ["s"] = function(line)
            local location = loclist:get_location_at(line)

            if location == nil then
                return
            end

            local task = location.data.task

            task:request_stop()
        end,
    },
}
