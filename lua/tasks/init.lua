local pasync = require("plenary.async")

local M = {}

M.config = {
    -- Array<Source>
    sources = {},
    -- Array<Runner>
    runners = {
        builtin = require("tasks.runners.builtin"),
    },
}

M.state = {
    -- Array<TaskSpec>
    specs = {},

    -- Array<Task>
    running_tasks = {},

    task_seq_nr = 1,
}

M._spec_listener_tx = nil

function M.setup(config)
    M.config = vim.tbl_extend("force", M.config, config or {})

    M.config.runners.builtin = require("tasks.runners.builtin")

    M.reload_specs()
end

function M._get_task_id()
    local id = M.state.task_seq_nr
    M.state.task_seq_nr = M.state.task_seq_nr + 1
    return id
end

function M.run(name, args, source_name)
    local spec
    local source

    if source_name == nil then
        for source_name, source_specs in pairs(M.state.specs) do
            if source_specs[name] ~= nil then
                spec = source_specs[name]
                source = M.config.sources[source_name]
                break
            end
        end
    else
        source = M.config.sources[source_name]
        spec = (M.state.specs[source_name] or {})[name]
    end

    if spec == nil then
        vim.notify(string.format("task spec '%s' not found", name), vim.log.levels.WARN)
        return
    end

    local runner_name = spec.runner_name or source.runner_name or "builtin"
    local runner = M.config.runners[runner_name]

    if runner == nil then
        vim.notify(string.format("runner '%s' not found", runner_name), vim.log.levels.ERROR)
        return
    end

    local task = runner:create_task(spec, args)
    local task_id = M._get_task_id()

    task:set_metadata({ spec = spec, source_name = source_name, runner_name = runner_name, task_id = task_id })

    M.state.running_tasks[task_id] = task

    task:on_finish(function()
        M.state.running_tasks[task_id] = nil
    end)

    vim.notify(string.format("starting task '%s' with id:'%d'", name, task_id), vim.log.levels.INFO)

    task:run()

    return task_id, task
end

function M.reload_specs()
    local sources = M.config.sources

    -- get all sources at once (first pass)
    local fns = vim.tbl_map(function(source_name)
        return function()
            local source = sources[source_name]
            local specs = source:get_specs()
            M._spec_listener_tx.send({ source_name = source_name, specs = specs })

            if source.start_specs_listener ~= nil then
                source:start_specs_listener(function(specs)
                    M._spec_listener_tx.send({ source_name = source_name, specs = specs })
                end)
            end
        end
    end, vim.tbl_keys(sources))

    pasync.util.run_all(fns)
end

function M._start_specs_listener()
    pasync.run(function()
        local tx, rx = pasync.control.channel.mpsc()

        M._spec_listener_tx = tx

        while true do
            local ret = rx.recv()

            local specs = ret.specs or {}

            for _, spec in pairs(specs) do
                spec.runner_name = spec.runner_name or "builtin"
            end

            M.state.specs[ret.source_name] = specs
        end
    end)
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

M._start_specs_listener()

return M
