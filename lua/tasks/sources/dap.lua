local Source = require("tasks.lib.source")
local conditions = require("tasks.lib.conditions")
local pasync = require("tasks.lib.async")
local fs = require("tasks.lib.fs")
local logger = require("tasks.logger")

local source = Source:create({
    conditions = { conditions.has_module("dap") },

    load_launchjson = true,
})

local function configuration_to_spec(config)
    local dependencies = {}

    if config.preLaunchTask ~= "" and config.preLaunchTask ~= nil then
        dependencies = { { spec_name = config.preLaunchTask } }
    end

    return config["name"],
        {
            fn = function(ctx)
                local terminated_tx, terminated_rx = pasync.control.channel.mpsc()

                local dap = require("dap")

                local handler_name = "tasks.nvim_task_id:" .. ctx.id

                dap.listeners.after["event_terminated"][handler_name] = function(_session, _body)
                    terminated_tx.send()
                end

                vim.schedule(function()
                    dap.run(config)
                end)

                pasync.run(function()
                    ctx.stop_request_receiver()
                    dap.terminate()
                    terminated_tx.send()
                end)

                terminated_rx.recv()

                dap.listeners.after["event_terminated"][handler_name] = nil
            end,

            dependencies = dependencies,

            dap_config = config,
        }
end

function source:get_specs()
    local dap = require("dap")

    local specs = {}
    for lang_name, lang in pairs(dap.configurations) do
        for _, config in ipairs(lang) do
            local name, spec = configuration_to_spec(config)

            name = string.format("%s [%s]", name, lang_name)

            specs[name] = spec
        end
    end

    local condition = conditions.file_exists(".vscode/launch.json")
    if not condition() then
        logger:debug("no '.vscode/launch.json'")
        return specs
    end

    local launchjson = fs.read_json_file(".vscode/launch.json")

    -- TODO: compounds: https://code.visualstudio.com/docs/editor/debugging#_compound-launch-configurations
    for _, config in ipairs(launchjson.configurations or {}) do
        local name, spec = configuration_to_spec(config)

        name = string.format("%s [launch.json]", name)

        specs[name] = spec
    end

    return specs
end

return source
