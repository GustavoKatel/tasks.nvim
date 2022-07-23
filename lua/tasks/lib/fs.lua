local pasync = require("tasks.lib.async")
local jsonc = require("tasks.jsonc")

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

    local ok, obj = pcall(vim.json.decode, data)
    if ok then
        return obj
    end

    ok, obj = pcall(jsonc.decode_async, data)
    assert(ok, "could not parse jsonc file. Make sure you have 'jsonc' grammar in treesitter")

    return obj
end

return M
