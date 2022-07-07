local Source = require("tasks.lib.source")

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
end)
