local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local previewers = require("telescope.previewers")
local conf = require("telescope.config").values

local tasks = require("tasks")

local tasks_actions = require("telescope._extensions.tasks.actions")

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
                preview_command = function(entry_preview, bufnr)
                    local output = vim.split(vim.inspect(entry_preview.value), "\n")
                    vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, output)
                end,
            }
        end,
    })
end

return function(opts)
    opts = opts or {}

    pickers
        .new(opts, {
            prompt_title = "tasks: all",
            finder = generate_new_finder(opts),
            sorter = conf.generic_sorter(opts),
            previewer = previewers.display_content.new(opts),
            attach_mappings = function()
                actions.select_default:replace(tasks_actions.run)
                return true
            end,
        })
        :find()
end
