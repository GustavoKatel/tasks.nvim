local Source = require("tasks.lib.source")
local reloaders = require("tasks.lib.reloaders")

local eq = assert.are.same

describe("base Source tests", function()
    it("creates basic sources", function()
        local source = Source:create({ test = "ok" })

        eq("ok", source.test)
    end)

    it("allows overrides with 'with' method", function()
        local source = Source:create({ test = "ok1" }):with({ test = "ok2" })

        eq("ok2", source.test)
    end)

    it("allows overrides from create_from_source_file", function()
        local source1 = Source:create_from_source_file({
            filename = "package.json",
        })

        local source2 = source1:with({ filename = "packages/my_package/package.json" })

        eq(reloaders.file_changed("package.json"), source1.reloaders[1])
        eq(1, #source1.reloaders)

        eq(reloaders.file_changed("packages/my_package/package.json"), source2.reloaders[1])
        eq(1, #source2.reloaders)
    end)
end)
