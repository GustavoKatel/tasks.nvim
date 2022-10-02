local pasync = require("tasks.lib.async")

local eq = assert.are.same

describe("tasks async utilities test", function()
    describe("async.async_vim_wrap", function()
        it("wraps inside a vim.schedule", function()
            local fn = pasync.async_vim_wrap(function(fname)
                return vim.fn.filereadable(vim.fn.expand(fname))
            end)

            pasync.util.block_on(function()
                local ret = fn("lua/tasks/init.lua")

                eq(1, ret)
            end)
        end)

        it("automatically wraps vim.fn functions", function()
            pasync.util.block_on(function()
                local ret = pasync.fn.filereadable(pasync.fn.expand("lua/tasks/init.lua"))

                eq(1, ret)
            end)
        end)
    end)
end)
