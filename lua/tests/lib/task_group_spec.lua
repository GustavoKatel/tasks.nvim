local TaskGroup = require("tasks.lib.task_group")
local Task = require("tasks.lib.task")
local pasync = require("plenary.async")
local task_state = require("tasks.lib.task_state")

local eq = assert.are.same

describe("task group", function()
    -- describe("normalize task groups", function()
    --     it("single task", function()
    --         local task = Task:new(function()
    --             pasync.util.sleep(500)
    --         end)
    --
    --         local tg = TaskGroup:new(task)
    --
    --         eq({ finished = 0, running = 0, total = 1 }, tg:get_state())
    --     end)
    --
    --     it("single group task", function()
    --         local task = Task:new(function()
    --             pasync.util.sleep(500)
    --         end)
    --
    --         local tg = TaskGroup:new({ task })
    --
    --         eq({ finished = 0, running = 0, total = 1 }, tg:get_state())
    --     end)
    --
    --     it("nested 1", function()
    --         local task = Task:new(function()
    --             pasync.util.sleep(500)
    --         end)
    --
    --         local tg = TaskGroup:new({ { task } })
    --
    --         eq({ finished = 0, running = 0, total = 1 }, tg:get_state())
    --     end)
    --
    --     it("nested 2", function()
    --         local task = Task:new(function()
    --             pasync.util.sleep(500)
    --         end)
    --
    --         local tg = TaskGroup:new({ { task }, task })
    --
    --         eq({ finished = 0, running = 0, total = 2 }, tg:get_state())
    --     end)
    --
    --     it("nested 3", function()
    --         local task = Task:new(function()
    --             pasync.util.sleep(500)
    --         end)
    --
    --         local tg = TaskGroup:new({ { task, task }, task, { { { { { { { task } } } } } } } })
    --
    --         eq({ finished = 0, running = 0, total = 4 }, tg:get_state())
    --     end)
    -- end)
    --
    -- it("runs and waits for task: single", function()
    --     local task = Task:new(function()
    --         pasync.util.sleep(500)
    --     end)
    --
    --     local tg = TaskGroup:new({ task })
    --
    --     eq({ finished = 0, running = 0, total = 1 }, tg:get_state())
    --
    --     pasync.run(function()
    --         tg:run()
    --     end)
    --
    --     eq(task_state.RUNNING, task:get_state())
    --     eq({ finished = 0, running = 1, total = 1 }, tg:get_state())
    --
    --     pasync.util.block_on(function()
    --         pasync.util.sleep(600)
    --
    --         eq(task_state.DONE, task:get_state())
    --     end)
    --
    --     eq({ finished = 1, running = 0, total = 1 }, tg:get_state())
    -- end)
    --
    -- it("runs and waits for task: single + cancellation", function()
    --     local task = Task:new(function(ctx)
    --         ctx.wait_stop_requested()
    --     end)
    --
    --     local tg = TaskGroup:new({ task })
    --
    --     eq({ finished = 0, running = 0, total = 1 }, tg:get_state())
    --
    --     pasync.run(function()
    --         tg:run()
    --     end)
    --
    --     task:request_stop()
    --
    --     eq(task_state.CANCELLED, task:get_state())
    --     eq({ finished = 1, running = 0, total = 1 }, tg:get_state())
    -- end)
    --
    -- it("runs and waits for task: muiltiple sequential", function()
    --     local task1 = Task:new(function()
    --         pasync.util.sleep(500)
    --     end)
    --     local task2 = Task:new(function()
    --         pasync.util.sleep(500)
    --     end)
    --
    --     local tg = TaskGroup:new({ task1, task2 })
    --
    --     eq({ finished = 0, running = 0, total = 2 }, tg:get_state())
    --
    --     pasync.run(function()
    --         tg:run()
    --     end)
    --
    --     eq(task_state.RUNNING, task1:get_state())
    --     eq(task_state.READY, task2:get_state())
    --     eq({ finished = 0, running = 1, total = 2 }, tg:get_state())
    --
    --     pasync.util.block_on(function()
    --         pasync.util.sleep(600)
    --
    --         eq(task_state.DONE, task1:get_state())
    --         eq(task_state.RUNNING, task2:get_state())
    --     end)
    --
    --     eq({ finished = 1, running = 1, total = 2 }, tg:get_state())
    --
    --     pasync.util.block_on(function()
    --         pasync.util.sleep(600)
    --
    --         eq(task_state.DONE, task1:get_state())
    --         eq(task_state.DONE, task2:get_state())
    --     end)
    --
    --     eq({ finished = 2, running = 0, total = 2 }, tg:get_state())
    -- end)

    it("runs and waits for task: muiltiple sequential + cancellation", function()
        local task1 = Task:new(function(ctx)
            ctx.wait_stop_requested()
        end)
        local task2 = Task:new(function(ctx)
            ctx.wait_stop_requested()
        end)

        local tg = TaskGroup:new({ task1, task2 })

        eq({ finished = 0, running = 0, total = 2 }, tg:get_state())

        pasync.run(function()
            tg:run()
        end)

        eq(task_state.RUNNING, task1:get_state())
        eq(task_state.READY, task2:get_state())
        eq({ finished = 0, running = 1, total = 2 }, tg:get_state())

        task1:request_stop()

        pasync.util.block_on(function()
            pasync.util.sleep(200)
        end)

        eq(task_state.CANCELLED, task1:get_state())
        eq(task_state.CANCELLED, task2:get_state())

        eq({ finished = 2, running = 0, total = 2 }, tg:get_state())
    end)

    it("runs and waits for task: muiltiple parallel", function()
        local task1 = Task:new(function()
            pasync.util.sleep(500)
        end)
        local task2 = Task:new(function()
            pasync.util.sleep(100)
        end)
        local task3 = Task:new(function()
            pasync.util.sleep(500)
        end)

        local tg = TaskGroup:new({ { task1, task2 }, task3 })

        eq({ finished = 0, running = 0, total = 3 }, tg:get_state())

        pasync.run(function()
            tg:run()
        end)

        eq(task_state.RUNNING, task1:get_state())
        eq(task_state.RUNNING, task2:get_state())
        eq(task_state.READY, task3:get_state())
        eq({ finished = 0, running = 2, total = 3 }, tg:get_state())

        pasync.util.block_on(function()
            pasync.util.sleep(600)

            eq(task_state.DONE, task1:get_state())
            eq(task_state.DONE, task2:get_state())
            eq(task_state.RUNNING, task3:get_state())
        end)

        eq({ finished = 2, running = 1, total = 3 }, tg:get_state())

        pasync.util.block_on(function()
            pasync.util.sleep(600)

            eq(task_state.DONE, task1:get_state())
            eq(task_state.DONE, task2:get_state())
            eq(task_state.DONE, task3:get_state())
        end)

        eq({ finished = 3, running = 0, total = 3 }, tg:get_state())
    end)
end)
