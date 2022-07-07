local M = {}

function M.assert_err(...)
    local err, ret = ...
    assert(not err, err)

    return ret
end

return M
