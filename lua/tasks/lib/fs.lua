local pasync = require("plenary.async")

local M = {}

local function assert_err(...)
    local err, ret = ...
    assert(not err, err)

    return ret
end

function M.read_file(path)
    local fd = assert_err(pasync.uv.fs_open(path, "r", 438))

    local stat = assert_err(pasync.uv.fs_fstat(fd))

    local data = assert_err(pasync.uv.fs_read(fd, stat.size, 0))

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
