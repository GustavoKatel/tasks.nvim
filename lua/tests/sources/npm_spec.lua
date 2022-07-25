local pasync = require("tasks.lib.async")
local source_npm = require("tasks.sources.npm")

local eq = assert.are.same

describe("npm tests", function()
    it("parses from package.json", function()
        pasync.util.block_on(function()
            local specs = source_npm:parser({ scripts = { my_script = "jest" } })
            eq({ "npm", "run", "my_script" }, specs.my_script.cmd)
        end)
    end)

    it("allows option overrides", function()
        local new_runner = source_npm:with({
            script_runner = { "yarn" },
            filename = "packages/my_package/package.json",
        })

        assert.is.truthy(source_npm.get_specs)
        assert.is.truthy(new_runner.get_specs)

        eq({ "yarn" }, new_runner.script_runner)
        eq({ "npm", "run" }, source_npm.script_runner)

        eq("packages/my_package/package.json", new_runner.filename)
        eq("package.json", source_npm.filename)
    end)
end)
