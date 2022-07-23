-- inspired by: https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/lua/null-ls/logger.lua

local Path = require("plenary.path")

local default_notify_opts = {
    title = "tasks",
}

local log = {
    level = "warn",

    notify_format = "[tasks] %s",
}

function log:setup(opts)
    opts = vim.tbl_extend("force", { level = "warn" }, opts or {})
    self.level = opts.level

    -- reset the handle
    self.__handle = nil
end

local function format_props(props)
    local ret = {}
    for key, value in pairs(props or {}) do
        table.insert(ret, string.format("%s=%s", key, vim.inspect(value)))
    end

    return table.concat(ret, ", ")
end

--- Adds a log entry using Plenary.log
---@param msg any
---@param props table key-value props to attach to the message
---@param level string [same as vim.log.log_levels]
function log:add_entry(msg, props, level)
    if not self.__notify_fmt then
        self.__notify_fmt = function(m, p)
            return string.format(self.notify_format, m, format_props(p))
        end
    end

    if self.level == "off" then
        return
    end

    if type(msg) == "table" then
        msg = vim.inspect(msg)
    end

    msg = string.format("%s | %s", msg, format_props(props))

    if self.__handle then
        self.__handle[level](msg)
        return
    end

    local default_opts = {
        plugin = "tasks",
        level = self.level or "warn",
        use_console = false,
        info_level = 4,
    }

    local plenary_log = require("plenary.log")

    local handle = plenary_log.new(default_opts)
    handle[level](msg)
    self.__handle = handle
end

---Retrieves the path of the logfile
---@return string path of the logfile
function log:get_path()
    local p = Path:new(vim.fn.stdpath("cache")) / "tasks.log"
    return p.filename
end

---Add a log entry at TRACE level
---@param msg any
---@param props table key-value props to attach to the message
function log:trace(msg, props)
    self:add_entry(msg, props, "trace")
end

---Add a log entry at DEBUG level
---@param msg any
---@param props table key-value props to attach to the message
function log:debug(msg, props)
    self:add_entry(msg, props, "debug")
end

---Add a log entry at INFO level
---@param msg any
---@param props table key-value props to attach to the message
function log:info(msg, props)
    self:add_entry(msg, props, "info")
end

---Add a log entry at WARN level
---@param msg any
---@param props table key-value props to attach to the message
function log:warn(msg, props)
    self:add_entry(msg, props, "warn")
    vim.notify(self.__notify_fmt(msg, props), vim.log.levels.WARN, default_notify_opts)
end

---Add a log entry at ERROR level
---@param msg any
---@param props table key-value props to attach to the message
function log:error(msg, props)
    self:add_entry(msg, props, "error")
    vim.notify(self.__notify_fmt(msg, props), vim.log.levels.ERROR, default_notify_opts)
end

setmetatable({}, log)
return log
