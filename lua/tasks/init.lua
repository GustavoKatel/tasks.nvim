local pasync = require("plenary.async")
local logger = require("tasks.logger")

local M = {}

local DefaultConfig = {
    -- Array<Source>
    sources = {},
    -- Array<Runner>
    runners = {
        builtin = require("tasks.runners.builtin"),
    },

    router = nil,

    logger = {
        level = "warn",
        notify_format = "[tasks] %s %s",
    },
}

M.config = vim.deepcopy(DefaultConfig)

M.state = {
    -- Array<TaskSpec>
    specs = {},

    -- Array<Task>
    running_tasks = {},

    task_seq_nr = 1,

    -- { name = <string>, source_name = <string> }
    last_spec_ran = nil,
}

M._spec_listener_tx = nil

function M.setup(config)
    local logger_opts = vim.tbl_deep_extend("force", DefaultConfig.logger, M.config.logger or {}, config.logger or {})
    M.config = vim.tbl_extend("force", M.config, config or {}, { logger = logger_opts })

    if M.config.runners.builtin == nil then
        M.config.runners.builtin = require("tasks.runners.builtin")
    end

    logger:setup(config.logger)

    M._init_sources()

    M.reload_specs()
end

function M._get_task_id()
    local id = M.state.task_seq_nr
    M.state.task_seq_nr = M.state.task_seq_nr + 1
    return id
end

function M.run(name, args, source_name, runner_opts)
    logger:debug("creating task from spec name", { name = name, source_name = source_name })
    local spec
    local source

    if source_name == nil then
        for _source_name, source_specs in pairs(M.state.specs) do
            if source_specs[name] ~= nil then
                spec = source_specs[name]
                source = M.config.sources[_source_name]
                source_name = _source_name
                break
            end
        end
    else
        source = M.config.sources[source_name]
        spec = (M.state.specs[source_name] or {})[name]
    end

    if spec == nil then
        logger:warn("task spec not found", { name = name, source_name = source_name })
        return
    end

    local runner_name = spec.runner_name or source.runner_name or "builtin"

    if M.config.router ~= nil then
        runner_name = M.config.router(name, spec, args, source_name) or runner_name
    end

    local runner = M.config.runners[runner_name]

    if runner == nil then
        logger:warn("runner not found", { runner_name = runner_name })
        return
    end

    local task = runner:create_task(spec, args, runner_opts)
    local task_id = M._get_task_id()

    task:set_metadata({
        spec = spec,
        spec_name = name,
        source_name = source_name,
        runner_name = runner_name,
        task_id = task_id,
    })

    M.state.running_tasks[task_id] = task

    task:on_finish(function()
        M.state.running_tasks[task_id] = nil
    end)

    logger:info(string.format("starting task '%s' with id:'%d'", name, task_id), { name = name, task_id = task_id })

    task:run()

    M.state.last_spec_ran = { name = name, args = args, source_name = source_name }

    return task_id, task
end

function M.run_last()
    if M.state.last_spec_ran == nil then
        logger:info("no last spec registered")
        return
    end

    return M.run(M.state.last_spec_ran.name, M.state.last_spec_ran.args, M.state.last_spec_ran.source_name)
end

local function pull_specs_from_source(source_name, source, logger_props)
    if not source:verify_conditions() then
        logger:debug("source skipped due to falsy conditions", { source_name = source_name })
        return
    end
    local ok, specs = pcall(source.get_specs, source)
    if not ok then
        logger:error(specs, vim.tbl_deep_extend("force", { source_name = source_name }, logger_props or {}))
        return
    end

    M._spec_listener_tx.send({ source_name = source_name, specs = specs })
    logger:debug("source get_specs done", { source_name = source_name, spec_count = #specs })
end

function M._init_sources()
    logger:debug("starting all sources", { source_count = #M.config.sources })

    local group_name = "TasksNvimSourceReloaders"
    vim.api.nvim_create_augroup(group_name, { clear = true })

    for source_name, source in pairs(M.config.sources) do
        local reloaders = source.reloaders or {}

        logger:debug("starting source: " .. source_name, { reloaders_count = #reloaders })

        for _, reloader in ipairs(reloaders) do
            local autocmd = vim.tbl_extend("force", reloader, {
                group = group_name,
                callback = function()
                    pasync.run(function()
                        pull_specs_from_source(source_name, source, { reloader = reloader })
                    end)
                end,
            })
            autocmd["event_name"] = nil
            vim.api.nvim_create_autocmd(reloader.event_name, autocmd)
        end
    end
end

function M.reload_specs()
    logger:debug("reloading all specs from all sources")

    local sources = M.config.sources

    -- get all sources at once (first pass)
    local fns = vim.tbl_map(function(source_name)
        return function()
            local source = sources[source_name]
            pull_specs_from_source(source_name, source, {})
        end
    end, vim.tbl_keys(sources))

    pasync.util.run_all(fns)
end

local function start_specs_listener()
    pasync.run(function()
        logger:debug("specs listener starting")
        local tx, rx = pasync.control.channel.mpsc()

        M._spec_listener_tx = tx

        while true do
            local ret = rx.recv()

            local specs = ret.specs or {}

            for _, spec in pairs(specs) do
                spec.runner_name = spec.runner_name or "builtin"
            end

            logger:debug("updating specs for source", { source_name = ret.source_name, spec_count = #specs })

            M.state.specs[ret.source_name] = specs
        end
    end)

    local group_name = "TasksNvimDirChanged"
    vim.api.nvim_create_augroup(group_name, { clear = true })
    vim.api.nvim_create_autocmd("DirChanged", {
        group = group_name,
        callback = function()
            logger:debug("reloading specs due to DirChanged")
            M.reload_specs()
        end,
    })
end

-- @param table opts
function M.get_specs(opts)
    opts = vim.tbl_deep_extend("force", { source_name = nil, runner_name = nil }, opts or {})

    local results = {}

    for source_name, specs in pairs(M.state.specs) do
        local source_match = opts.source_name == nil or opts.source_name == source_name

        if source_match then
            results[source_name] = {}

            for spec_name, spec in pairs(specs) do
                if opts.runner_name == nil or opts.runner_name == spec.runner_name then
                    results[source_name][spec_name] = vim.deepcopy(spec)
                end
            end
        end
    end

    return results
end

function M.get_running_tasks(opts)
    --return filter_tasks(opts, M.state.running_tasks)
    opts = vim.tbl_deep_extend("force", { source_name = nil, runner_name = nil }, opts or {})

    local results = {}

    for task_id, task in pairs(M.state.running_tasks) do
        local source_match = opts.source_name == nil or opts.source_name == task:get_source_name()
        local runner_match = opts.runner_name == nil or opts.runner_name == task:get_runner_name()

        if source_match and runner_match then
            results[task_id] = task
        end
    end

    return results
end

function M.get_log_path()
    return logger:get_path()
end

start_specs_listener()

return M
