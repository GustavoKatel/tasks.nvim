local tasks = require("tasks")

return function(icon)
    return function()
        local running = tasks.get_running_tasks()

        icon = icon or ""

        return "" .. icon .. " " .. #vim.tbl_keys(running)
    end
end
