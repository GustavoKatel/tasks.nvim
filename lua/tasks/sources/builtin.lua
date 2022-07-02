local M = {}

function M.new_builtin_source(specs)
    local source = {}

    function source:get_specs()
        return specs
    end

    return source
end

return M
