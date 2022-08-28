local Task = require("tasks.lib.task")
local pasync = require("plenary.async")
local task_state = require("tasks.lib.task_state")

local eq = assert.are.same

describe("task", function()
    it("updates task state after run", function()
        local task = Task:new(function()
            pasync.util.sleep(500)
        end)

        eq(task_state.READY, task:get_state())
        pasync.run(function()
            task:run()
        end)

        eq(task_state.RUNNING, task:get_state())

        pasync.util.block_on(function()
            pasync.util.sleep(600)

            eq(task_state.DONE, task:get_state())
        end)
    end)

    it("gets values from metadata", function()
        local task = Task:new(function()
            pasync.util.sleep(500)
        end)

        eq(nil, task:get_spec_name())
        eq(nil, task:get_source_name())
        eq(nil, task:get_runner_name())

        task:set_metadata({ source_name = "test", spec_name = "my_task", runner_name = "test_runner" })

        eq("my_task", task:get_spec_name())
        eq("test", task:get_source_name())
        eq("test_runner", task:get_runner_name())
    end)

    it("calls on_finish callbacks", function()
        local task = Task:new(function()
            pasync.util.sleep(500)
        end)

        local finished = false

        task:on_finish(function()
            finished = true
        end)

        task:run()

        eq(task_state.RUNNING, task:get_state())

        pasync.util.block_on(function()
            pasync.util.sleep(600)

            eq(true, finished)
        end)
    end)

    it("stops on request", function()
        local stop_requested = false

        local task = Task:new(function(ctx)
            -- this will just block waiting for the stop request
            ctx.wait_stop_requested()

            stop_requested = true
        end)

        task:run()

        eq(task_state.RUNNING, task:get_state())
        eq(false, stop_requested)

        pasync.util.block_on(function()
            pasync.util.sleep(300)
            eq(task_state.RUNNING, task:get_state())

            eq(false, stop_requested)

            task:request_stop()

            pasync.util.sleep(300)
            eq(task_state.CANCELLED, task:get_state())

            eq(true, stop_requested)
        end)
    end)
end)
