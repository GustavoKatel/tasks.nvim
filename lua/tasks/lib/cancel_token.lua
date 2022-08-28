local pasync = require("tasks.lib.async")

local CancelToken = {}

local function set_parent(token, parent)
    pasync.run(function()
        parent:wait()

        token:cancel()
    end)
end

function CancelToken:new(parent)
    local condvar = pasync.control.Condvar.new()

    local token = {
        parent = parent,

        condvar = condvar,

        cancelled = false,
    }

    setmetatable(token, self)
    self.__index = self

    if parent then
        set_parent(token, parent)
    end

    return token
end

function CancelToken:is_cancelled()
    return self.cancelled
end

function CancelToken:wait()
    if self.cancelled then
        return
    end

    self.condvar:wait()
end

function CancelToken:cancel()
    if self.cancelled then
        return
    end

    self.cancelled = true
    self.condvar:notify_all()
end

return CancelToken
