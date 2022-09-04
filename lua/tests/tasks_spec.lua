local tasks = require("tasks")
local Tasks = require("tasks.lib.task")
local Source = require("tasks.lib.source")
local pasync = require("plenary.async")
local reloaders = require("tasks.lib.reloaders")
local priority_router = require("tasks.routers.priority")
local default_runners = require("tasks.runners.defaults")

local test_helpers = require("tests.helpers")

local eq = assert.are.same
local neq = assert.are_not.same

describe("init", function()
    it("reloads task specs in setup", function()
        test_helpers.tasks_setup({
            sources = {
                test = Source:create({
                    specs = {
                        spec_1 = {
                            vim_cmd = "echo 'hello'",
                        },
                    },
                }),
            },
        })

        assert.is.truthy(tasks.config.runners.vim_cmd)
        assert.is.truthy(tasks._spec_listener_tx)

        local specs = tasks.get_specs()
        eq("echo 'hello'", specs.test.spec_1.vim_cmd)
    end)

    it("creates reloaders from sources", function()
        local reloaded = false

        test_helpers.tasks_setup({
            sources = {
                test = Source:create({
                    specs = {
                        spec_1 = {
                            vim_cmd = "echo 'hello'",
                        },
                    },
                }),

                custom_source = Source:create({
                    get_specs = function()
                        if reloaded then
                            return {
                                spec_2 = {
                                    vim_cmd = "echo 'test'",
                                },
                            }
                        end

                        return nil
                    end,
                    reloaders = {
                        reloaders.autocmd("User", "TestSource"),
                    },
                }),
            },
        })

        local specs = tasks.get_specs({ source_name = "custom_source" })
        assert.is.falsy(specs.custom_source.spec_2)

        local autocmds = vim.api.nvim_get_autocmds({
            group = "TasksNvimSourceReloaders",
            event = { "User" },
            pattern = { "TestSource" },
        })

        eq(1, #autocmds)

        reloaded = true
        vim.cmd("doautocmd TasksNvimSourceReloaders User TestSource")

        pasync.util.block_on(function()
            pasync.util.sleep(600)

            specs = tasks.get_specs({ source_name = "custom_source" })

            eq("echo 'test'", specs.custom_source.spec_2.vim_cmd)
        end)
    end)

    it("adds default runners during setup", function()
        test_helpers.tasks_setup()

        assert.is.truthy(tasks.config.runners.functions)
    end)

    describe("get_specs", function()
        it("get specs from a single source", function()
            test_helpers.tasks_setup({
                sources = {
                    test = Source:create({
                        specs = {
                            spec_1 = {
                                vim_cmd = "echo 'hello'",
                            },
                        },
                    }),
                    test2 = Source:create({
                        specs = {
                            spec_2 = {
                                vim_cmd = "echo 'hello2'",
                            },
                        },
                    }),
                },
            })

            local specs = tasks.get_specs({ source_name = "test2" })
            assert.is.falsy(specs.test)
            eq("echo 'hello2'", specs.test2.spec_2.vim_cmd)
        end)
    end)

    describe("get_running_tasks", function()
        before_each(function()
            test_helpers.tasks_setup({
                sources = {
                    test = Source:create({
                        specs = {
                            wait_stop = {
                                fn = function(ctx)
                                    ctx.wait_stop_requested()
                                end,
                            },
                            spec_2 = {
                                vim_cmd = "echo 'hello2'",
                            },
                        },
                    }),
                    test2 = Source:create({
                        specs = {
                            spec_2 = {
                                vim_cmd = "echo 'hello3'",
                            },
                            spec_3 = {
                                vim_cmd = "echo 'hello4'",
                            },
                        },
                    }),
                },
            })
        end)

        it("returns nothing if no tasks are running", function()
            local tasks_running = tasks.get_running_tasks()
            eq(0, #vim.tbl_keys(tasks_running))
        end)

        it("returns the correct running tasks", function()
            tasks.run("wait_stop")

            local tasks_running = tasks.get_running_tasks()
            eq(1, #vim.tbl_keys(tasks_running))

            -- second run
            tasks.run("wait_stop")

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
            test_helpers.tasks_setup({
                sources = {
                    test = Source:create({
                        specs = {
                            wait_stop_builtin = {
                                fn = function(ctx)
                                    ctx.wait_stop_requested()
                                end,
                            },
                            wait_stop_custom = {
                                fn = function(ctx)
                                    ctx.wait_stop_requested()
                                end,
                            },
                            wait_stop_custom_2 = {
                                fn = function(ctx)
                                    ctx.wait_stop_requested()
                                end,
                            },
                            spec_2 = {
                                vim_cmd = "echo 'hello2'",
                            },

                            invalid_spec = {
                                test = true,
                            },
                        },
                    }),
                    test2 = Source:create({
                        specs = {
                            spec_2 = {
                                vim_cmd = "echo 'hello3'",
                            },
                            spec_3 = {
                                vim_cmd = "echo 'hello4'",
                            },
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

        it("runs using the builtin runners", function()
            local _, task = tasks.run("wait_stop_builtin")
            task:request_stop()
        end)

        it("runs using custom runner", function()
            local _, task = tasks.run("wait_stop_custom")
            task:request_stop()
        end)

        it("fails if runner cannot resolve", function()
            tasks.config.runners.custom_runner = nil
            local task_id, task = tasks.run("invalid_spec")
            eq(nil, task_id)
            eq(nil, task)
        end)

        it("fails if spec not found", function()
            local task_id, task = tasks.run("invalid_task")
            eq(nil, task_id)
            eq(nil, task)
        end)

        it("sets the last spec correctly", function()
            local task_id, task = tasks.run("wait_stop_builtin")
            task:request_stop()

            eq("wait_stop_builtin", tasks.state.last_spec_ran.name)
            eq(nil, tasks.state.last_spec_ran.args)
            eq("test", tasks.state.last_spec_ran.source_name)

            local new_task_id, new_task = tasks.run_last()
            new_task:request_stop()
            neq(task_id, new_task_id)
            eq("wait_stop_builtin", task:get_spec_name())
            eq("test", task:get_source_name())
        end)

        it("makes use of the router function", function()
            test_helpers.tasks_setup({
                sources = {
                    test = Source:create({
                        specs = {
                            wait_stop_builtin = {
                                fn = function(ctx)
                                    ctx.wait_stop_requested()
                                end,
                            },
                            wait_stop_custom = {
                                fn = function(ctx)
                                    ctx.wait_stop_requested()
                                end,
                            },
                            wait_stop_custom_2 = {
                                fn = function(ctx)
                                    ctx.wait_stop_requested()
                                end,
                            },
                            spec_2 = {
                                vim_cmd = "echo 'hello2'",
                            },
                        },
                    }),
                    test2 = Source:create({
                        specs = {
                            spec_2 = {
                                vim_cmd = "echo 'hello3'",
                            },
                            spec_3 = {
                                vim_cmd = "echo 'hello4'",
                            },
                        },
                    }),
                },
                runners = {
                    custom_runner = {
                        create_task = function(_, spec, args)
                            return Tasks:new(spec.fn, args)
                        end,
                    },

                    custom_runner_2 = {
                        create_task = function(_, spec, args)
                            return Tasks:new(spec.fn, args)
                        end,
                    },
                },

                router = function(name, spec, args, _runners)
                    local router_table = {
                        wait_stop_builtin = "custom_runner",
                    }

                    return router_table[name] or priority_router(name, spec, args, default_runners)
                end,
            })

            local _, task = tasks.run("wait_stop_builtin")
            task:request_stop()
            eq("custom_runner", task:get_runner_name())

            _, task = tasks.run("wait_stop_custom")
            task:request_stop()
            eq("functions", task:get_runner_name())
        end)

        it("get_task_dependencies", function()
            local _, task = tasks.run("spec_3")
            eq(true, task ~= nil)
        end)
    end)
end)
