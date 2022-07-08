local pasync = require("plenary.async")

local M = {}

local helpers = {}

setmetatable(M, {
    __index = function(_, key)
        if pasync[key] ~= nil then
            return pasync[key]
        end

        return helpers[key]
    end,
})

function helpers.async_vim_wrap(input_cb)
    return function(...)
        local args = { ... }
        return pasync.wrap(
            vim.schedule_wrap(function(async_cb)
                async_cb(input_cb(unpack(args)))
            end),
            1
        )()
    end
end

helpers.fn = {}
setmetatable(helpers.fn, {
    __index = function(_, key)
        assert(vim.fn[key] ~= nil)
        return helpers.async_vim_wrap(function(...)
            return vim.fn[key](...)
        end)
    end,
})

return M
