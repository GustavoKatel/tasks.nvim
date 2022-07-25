local pasync = require("tasks.lib.async")

local M = {}

function M.file_exists(filename)
    return function()
        return pasync.fn.filereadable(pasync.fn.expand(filename)) == 1
    end
end

function M.has_module(module_name)
    return function()
        local ok, _ = pcall(require, module_name)
        return ok
    end
end

return M
