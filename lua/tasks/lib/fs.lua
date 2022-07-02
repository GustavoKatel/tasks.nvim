local pasync = require("plenary.async")

local M = {}

function M.read_file(path)
    local err, fd = pasync.uv.fs_open(path, "r", 438)
    assert(not err, err)

    local err, stat = pasync.uv.fs_fstat(fd)
    assert(not err, err)

    local err, data = pasync.uv.fs_read(fd, stat.size, 0)
    assert(not err, err)

    err = pasync.uv.fs_close(fd)
    assert(not err, err)

    return data
end

function M.read_json_file(path)
    local data = M.read_file(path)

    local obj = vim.json.decode(data)

    return obj
end

return M
