local pasync = require("tasks.lib.async")

local M = {}

function M.file_exists(filename)
    return function()
        return pasync.fn.filereadable(pasync.fn.expand(filename)) == 1
    end
end

return M
