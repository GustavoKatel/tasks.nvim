local pasync = require("tasks.lib.async")

local M = {}

function M.file_exists(filename)
    return function()
        return {
            result = pasync.fn.filereadable(pasync.fn.expand(filename)) == 1,
            message = string.format("file '%s' does not exist", filename),
        }
    end
end

function M.has_module(module_name)
    return function()
        local ok, _ = pcall(require, module_name)
        return { result = ok, message = string.format('module "%s" could not be found', module_name) }
    end
end

return M
