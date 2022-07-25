local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values

local tasks = require("tasks")

local tasks_actions = require("telescope._extensions.tasks.actions")
local tasks_telescope_config = require("telescope._extensions.tasks.config")

-- heavily inspired by: https://github.com/ThePrimeagen/harpoon/blob/master/lua/telescope/_extensions/marks.lua

local generate_results_from_specs = function(_opts)
    local results = {}

    for task_id, task in pairs(tasks.get_running_tasks()) do
        table.insert(results, { task_id = task_id, task = task })
    end

    return results
end

local generate_new_finder = function(opts)
    return finders.new_table({
        results = generate_results_from_specs(opts),
        entry_maker = function(entry)
            local line = string.format(
                "%s [%s] [id: %d]",
                entry.task:get_spec_name(),
                entry.task:get_source_name(),
                entry.task_id
            )
            return {
                value = entry,
                display = line,
                ordinal = entry.task:get_started_time(),
            }
        end,
    })
end

return function(opts)
    opts = opts or {}

    pickers
        .new(opts, {
            prompt_title = "tasks: running",
            finder = generate_new_finder(opts),
            sorter = conf.generic_sorter(opts),
            attach_mappings = function(prompt_bufnr, map)
                actions.select_default:replace(tasks_actions.open_buffer())

                tasks_telescope_config.attach_mappings("running", prompt_bufnr, map)
                return true
            end,
        })
        :find()
end
