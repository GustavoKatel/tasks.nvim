local pasync = require("plenary.async")
local utils = require("tasks.utils")

local M = {}

function M.read_file(path)
    local fd = utils.assert_err(pasync.uv.fs_open(path, "r", 438))

    local stat = utils.assert_err(pasync.uv.fs_fstat(fd))

    local data = utils.assert_err(pasync.uv.fs_read(fd, stat.size, 0))

    local err = pasync.uv.fs_close(fd)
    assert(not err, err)

    return data
end

function M.read_json_file(path)
    local data = M.read_file(path)

    local obj = vim.json.decode(data)

    return obj
end

return M
