local pasync = require("tasks.lib.async")
local Task = require("tasks.lib.task")

local _next_id = 1

local TaskGroup = {}

local function normalize_sub_group(subgroup)
    assert(
        type(subgroup) == "table",
        string.format("invalid task in TaskGroup. Expected 'Task' or table, got '%s'", type(subgroup))
    )

    local ret = {}

    for _, task_or_subgroup in ipairs(subgroup) do
        if getmetatable(task_or_subgroup) == Task then
            table.insert(ret, task_or_subgroup)
        else
            for _, t in ipairs(normalize_sub_group(task_or_subgroup)) do
                table.insert(ret, t)
            end
        end
    end

    return ret
end

local function normalize_group_def(group)
    local ret = {}

    if getmetatable(group) == Task then
        table.insert(ret, { group })
        return ret
    end

    for _, task_or_subgroup in ipairs(group or {}) do
        if getmetatable(task_or_subgroup) == Task then
            table.insert(ret, { task_or_subgroup })
        elseif task_or_subgroup ~= nil then
            table.insert(ret, normalize_sub_group(task_or_subgroup))
        end
    end

    return ret
end

-- @param group_def table list of Task to run sequentially
-- each item can be a Task or a nested list of Task, which will run all Tasks in parallel
function TaskGroup:new(group_def)
    assert(type(group_def) == "table", "'group_def' need to be table or Task")

    local id = _next_id
    _next_id = _next_id + 1

    local stop_tx, stop_rx = pasync.control.channel.oneshot()

    local tg = {
        id = id,

        is_stopped = false,

        finished = {},
        running = {},

        count_lock = false,
        state_cache = nil,

        events = {},

        group = normalize_group_def(group_def),

        stop_tx = stop_tx,
        stop_rx = stop_rx,
    }

    setmetatable(tg, self)
    self.__index = self
    return tg
end

function TaskGroup:run_group_level(tasks)
    local cos = {}

    for _, task in ipairs(tasks) do
        local finished_tx, finished_rx = pasync.control.channel.oneshot()
        task:on_finish(function()
            finished_tx()
            self:update_counters(function()
                self.finished[task:get_id()] = task
                self.running[task:get_id()] = nil
            end)
        end)

        self:update_counters(function()
            self.running[task:get_id()] = task
        end)
        task:run()
        table.insert(cos, function()
            finished_rx()
        end)
    end

    pasync.util.join(cos)
end

function TaskGroup:run()
    local current_level = {}

    pasync.run(function()
        self.stop_rx()

        for _, task in ipairs(current_level) do
            task:request_stop()
        end
    end)

    for _, tasks in ipairs(self.group) do
        if self.is_stopped then
            break
        end

        self.current_level = tasks
        self:run_group_level(tasks)
    end
end

function TaskGroup:request_stop()
    self.stop_tx()
end

function TaskGroup:get_total_tasks()
    local total = 0

    for _, tasks in ipairs(self.group) do
        total = total + #tasks
    end

    return total
end

function TaskGroup:update_counters(cb)
    pasync.run(function()
        self.count_lock = true

        local ok, ret_or_err = pcall(cb)

        self.count_lock = false

        if not ok then
            error(ret_or_err)
        end
    end)
end

function TaskGroup:get_state()
    -- if in the middle of an update, use previous cache (if any)
    if self.count_lock and self.state_cache ~= nil then
        return self.state_cache
    end

    self.state_cache = {
        finished = #vim.tbl_keys(self.finished),
        running = #vim.tbl_keys(self.running),
        total = self:get_total_tasks(),
    }

    return self.state_cache
end

function TaskGroup:on_finish(fn)
    self.events["finish"] = self.events["finish"] or {}

    table.insert(self.events["finish"], fn)
end

function TaskGroup:dispatch_event(event_name, args)
    local events = self.events[event_name] or {}

    for _, fn in ipairs(events) do
        fn(args)
    end
end

function TaskGroup:get_id()
    return self.id
end

return TaskGroup
