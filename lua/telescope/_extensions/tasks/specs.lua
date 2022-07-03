local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values

local tasks = require("tasks")

-- heavily inspired by: https://github.com/ThePrimeagen/harpoon/blob/master/lua/telescope/_extensions/marks.lua

local generate_results_from_specs = function(_opts)
    local results = {}

    for source_name, source_specs in pairs(tasks.get_specs()) do
        for spec_name, spec in pairs(source_specs) do
            table.insert(results, { spec_name = spec_name, source_name = source_name, spec = spec })
        end
    end

    return results
end

local generate_new_finder = function(opts)
    return finders.new_table({
        results = generate_results_from_specs(opts),
        entry_maker = function(entry)
            local line = string.format("%s [%s]", entry.spec_name, entry.source_name)
            return {
                value = entry,
                display = line,
                ordinal = line,
            }
        end,
    })
end

return function(opts)
    opts = opts or {}

    pickers.new(opts, {
        prompt_title = "tasks: all",
        finder = generate_new_finder(opts),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, _map)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()

                local entry = selection.value

                tasks.run(entry.spec_name, nil, entry.source_name)
            end)
            return true
        end,
    }):find()
end
