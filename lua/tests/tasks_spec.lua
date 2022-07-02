local tasks = require("tasks")
local Tasks = require("tasks.lib.task")
local builtin_source = require("tasks.sources.builtin")
local pasync = require("plenary.async")

local eq = assert.are.same

local function tasks_setup(config)
    tasks.state.specs = {}
    tasks.state.running_tasks = {}
    tasks.state.task_seq_nr = 1

    tasks.setup(config)
end

describe("init", function()
    it("reloads task specs in setup", function()
        tasks_setup({
            sources = {
                test = builtin_source.new_builtin_source({
                    spec_1 = {
                        vcmd = "echo 'hello'",
                    },
                }),
            },
        })

        assert.is.truthy(tasks.config.runners.builtin)
        assert.is.truthy(tasks._spec_listener_tx)

        local specs = tasks.get_specs()
        eq("echo 'hello'", specs.test.spec_1.vcmd)
    end)

    it("starts listening to specs from sources", function()
        tasks_setup({
            sources = {
                test = builtin_source.new_builtin_source({
                    spec_1 = {
                        vcmd = "echo 'hello'",
                    },
                }),

                custom_source = {
                    get_specs = function()
                        return {}
                    end,

                    start_specs_listener = function(_, tx)
                        pasync.run(function()
                            for i = 1, 4 do
                                pasync.util.sleep(500)
                                tx({ spec_2_1 = { vcmd = tostring(i) }, spec_2_2 = { vcmd = tostring(i + 1) } })
                            end
                        end)
                    end,
                },
            },
        })

        local specs = tasks.get_specs({ source_name = "custom_source" })
        assert.is.falsy(specs.custom_source.spec_2_1)
        assert.is.falsy(specs.custom_source.spec_2_2)

        pasync.util.block_on(function()
            pasync.util.sleep(500)

            specs = tasks.get_specs({ source_name = "custom_source" })

            eq("1", specs.custom_source.spec_2_1.vcmd)
            eq("2", specs.custom_source.spec_2_2.vcmd)

            pasync.util.sleep(500)

            specs = tasks.get_specs({ source_name = "custom_source" })

            eq("2", specs.custom_source.spec_2_1.vcmd)
            eq("3", specs.custom_source.spec_2_2.vcmd)
        end)
    end)

    describe("get_specs", function()
        it("get specs from a single source", function()
            tasks_setup({
                sources = {
                    test = builtin_source.new_builtin_source({
                        spec_1 = {
                            vcmd = "echo 'hello'",
                        },
                    }),
                    test2 = builtin_source.new_builtin_source({
                        spec_2 = {
                            vcmd = "echo 'hello2'",
                        },
                    }),
                },
            })

            local specs = tasks.get_specs({ source_name = "test2" })
            assert.is.falsy(specs.test)
            eq("echo 'hello2'", specs.test2.spec_2.vcmd)
        end)

        it("get specs from a single runner", function()
            tasks_setup({
                sources = {
                    test = builtin_source.new_builtin_source({
                        spec_1 = {
                            vcmd = "echo 'hello1'",
                            runner_name = "runner1",
                        },
                        spec_2 = {
                            vcmd = "echo 'hello2'",
                            runner_name = "runner2",
                        },
                    }),
                    test2 = builtin_source.new_builtin_source({
                        spec_2 = {
                            vcmd = "echo 'hello3'",
                            runner_name = "runner1",
                        },
                        spec_3 = {
                            vcmd = "echo 'hello4'",
                        },
                    }),
                },
            })

            local specs = tasks.get_specs({ runner_name = "runner2" })
            eq(1, #vim.tbl_keys(specs.test))
            eq(0, #vim.tbl_keys(specs.test2))
            eq("echo 'hello2'", specs.test.spec_2.vcmd)
        end)

        it("get specs from a single runner: multiple results", function()
            tasks_setup({
                sources = {
                    test = builtin_source.new_builtin_source({
                        spec_1 = {
                            vcmd = "echo 'hello1'",
                            runner_name = "runner1",
                        },
                        spec_2 = {
                            vcmd = "echo 'hello2'",
                            runner_name = "runner2",
                        },
                    }),
                    test2 = builtin_source.new_builtin_source({
                        spec_2 = {
                            vcmd = "echo 'hello3'",
                            runner_name = "runner1",
                        },
                        spec_3 = {
                            vcmd = "echo 'hello4'",
                        },
                    }),
                },
            })

            local specs = tasks.get_specs({ runner_name = "runner1" })
            eq(1, #vim.tbl_keys(specs.test))
            eq(1, #vim.tbl_keys(specs.test2))
            eq("echo 'hello1'", specs.test.spec_1.vcmd)
            eq("echo 'hello3'", specs.test2.spec_2.vcmd)
        end)
    end)

    describe("get_running_tasks", function()
        before_each(function()
            tasks_setup({
                sources = {
                    test = builtin_source.new_builtin_source({
                        wait_stop = {
                            fn = function(ctx)
                                ctx.stop_request_receiver()
                            end,
                        },
                        spec_2 = {
                            vcmd = "echo 'hello2'",
                        },
                    }),
                    test2 = builtin_source.new_builtin_source({
                        spec_2 = {
                            vcmd = "echo 'hello3'",
                        },
                        spec_3 = {
                            vcmd = "echo 'hello4'",
                        },
                    }),
                },
            })
        end)

        it("returns nothing if no tasks are running", function()
            local tasks = tasks.get_running_tasks()
            eq(0, #vim.tbl_keys(tasks))
        end)

        it("returns the correct running tasks", function()
            local task_id = tasks.run("wait_stop")

            eq(1, task_id)

            local tasks_running = tasks.get_running_tasks()
            eq(1, #vim.tbl_keys(tasks_running))

            -- second run
            task_id = tasks.run("wait_stop")

            eq(2, task_id)

            tasks_running = tasks.get_running_tasks()
            eq(2, #vim.tbl_keys(tasks_running))

            -- stop the first
            tasks_running[1]:request_stop()

            tasks_running = tasks.get_running_tasks()
            eq(1, #vim.tbl_keys(tasks_running))
        end)
    end)

    describe("run", function()
        before_each(function()
            tasks_setup({
                sources = {
                    test = builtin_source.new_builtin_source({
                        wait_stop_builtin = {
                            fn = function(ctx)
                                ctx.stop_request_receiver()
                            end,
                        },
                        wait_stop_custom = {
                            fn = function(ctx)
                                ctx.stop_request_receiver()
                            end,
                            runner_name = "custom_runner",
                        },
                        wait_stop_custom_2 = {
                            fn = function(ctx)
                                ctx.stop_request_receiver()
                            end,
                            runner_name = "custom_runner_2",
                        },
                        spec_2 = {
                            vcmd = "echo 'hello2'",
                        },
                    }),
                    test2 = builtin_source.new_builtin_source({
                        spec_2 = {
                            vcmd = "echo 'hello3'",
                        },
                        spec_3 = {
                            vcmd = "echo 'hello4'",
                        },
                    }),
                },
                runners = {
                    custom_runner = {
                        create_task = function(_, spec, args)
                            return Tasks:new(spec.fn, args)
                        end,
                    },
                },
            })
        end)

        it("runs using the builtin runner", function()
            local task_id, task = tasks.run("wait_stop_builtin")
            eq(1, task_id)
            task:request_stop()
        end)

        it("runs using custom runner", function()
            local task_id, task = tasks.run("wait_stop_custom")
            eq(1, task_id)
            task:request_stop()
        end)

        it("fails if runner not found", function()
            local task_id, task = tasks.run("wait_stop_custom_2")
            eq(nil, task_id)
            eq(nil, task)
        end)

        it("fails if spec not found", function()
            local task_id, task = tasks.run("invalid_task")
            eq(nil, task_id)
            eq(nil, task)
        end)
    end)
end)
