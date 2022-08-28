local pasync = require("tasks.lib.async")

local CancelToken = {}

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
        token:prepend(parent)
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
    self.cancelled = true
    self.condvar:notify_all()
end

function CancelToken:prepend(token)
    pasync.run(function()
        token:wait()

        self:cancel()
    end)
end

return CancelToken
