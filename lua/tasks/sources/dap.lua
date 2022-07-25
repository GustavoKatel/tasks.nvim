local Source = require("tasks.lib.source")
local conditions = require("tasks.lib.conditions")
local pasync = require("tasks.lib.async")
local fs = require("tasks.lib.fs")

local source = Source:create({
    conditions = { conditions.has_module("dap") },

    load_launchjson = true,
})

local function configuration_to_spec(config)
    return config["name"],
        {
            fn = function(ctx)
                local terminated_tx, terminated_rx = pasync.control.channel.oneshot()

                local dap = require("dap")

                vim.schedule(function()
                    dap.run(config)
                end)

                local timer = vim.loop.new_timer()
                timer:start(100, 500, function()
                    if dap.session() == nil then
                        timer:stop()
                        timer:close()
                        terminated_tx()
                    end
                end)

                pasync.run(function()
                    ctx.stop_request_receiver()
                    terminated_tx()
                end)

                terminated_rx()

                vim.schedule(function()
                    if dap.session() ~= nil then
                        dap.terminate()
                    end
                end)
            end,

            dependencies = config.preLaunchTask ~= "" and { { spec_name = config.preLaunchTask } } or {},

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
        print("no launch.json")
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

--return M
