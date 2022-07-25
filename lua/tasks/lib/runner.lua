local Runner = {}

Runner.__index = Runner

function Runner:create(opts)
    opts = vim.tbl_extend("force", self, opts or {})

    local obj = setmetatable(opts, self)

    return obj
end

function Runner:with(opts_overrides)
    return self:create(opts_overrides)
end

function Runner:create_task(_spec, _args)
    assert(false, "not implemented")
end

return Runner
