local pasync = require("plenary.async")
local mock = require("luassert.mock")
local match = require("luassert.match")
local source_tasksjson = require("tasks.sources.tasksjson")
local fs = require("tasks.lib.fs")

local eq = assert.are.same

describe("source tasksjson tests", function()
    local fs_mock
    local api_mock

    before_each(function()
        fs_mock = mock(fs, true)
        api_mock = mock(vim.api, true)
    end)

    after_each(function()
        mock.revert(fs_mock)
        mock.revert(api_mock)
    end)

    it("reads from tasks.json", function()
        fs_mock.read_json_file.returns({
            tasks = {
                {
                    label = "Run tests",
                    type = "process",
                    command = "./scripts/test.sh",
                },
            },
        })

        pasync.util.block_on(function()
            local specs = source_tasksjson:get_specs(nil)

            eq({ "./scripts/test.sh" }, specs["Run tests"].cmd)
        end)
    end)

    it("reads from tasks.json: without label", function()
        fs_mock.read_json_file.returns({
            tasks = {
                {
                    command = "./scripts/test.sh",
                },
            },
        })

        pasync.util.block_on(function()
            local specs = source_tasksjson:get_specs(nil)

            eq({ "./scripts/test.sh" }, specs["task 1"].cmd)
        end)
    end)

    it("reads from tasks.json: without label and with group (test)", function()
        fs_mock.read_json_file.returns({
            tasks = {
                {
                    command = "./scripts/test.sh",
                    group = "test",
                },
            },
        })

        pasync.util.block_on(function()
            local specs = source_tasksjson:get_specs(nil)

            eq({ "./scripts/test.sh" }, specs["Test"].cmd)
        end)
    end)

    it("reads from tasks.json: without label and with group (build)", function()
        fs_mock.read_json_file.returns({
            tasks = {
                {
                    command = "./scripts/test.sh",
                    group = "build",
                },
            },
        })

        pasync.util.block_on(function()
            local specs = source_tasksjson:get_specs(nil)

            eq({ "./scripts/test.sh" }, specs["Build"].cmd)
        end)
    end)

    it("reads from tasks.json: without label and with group (test kind)", function()
        fs_mock.read_json_file.returns({
            tasks = {
                {
                    command = "./scripts/test.sh",
                    group = {
                        kind = "test",
                    },
                },
            },
        })

        pasync.util.block_on(function()
            local specs = source_tasksjson:get_specs(nil)

            eq({ "./scripts/test.sh" }, specs["Test"].cmd)
        end)
    end)

    it("reads from tasks.json: npm script", function()
        fs_mock.read_json_file.returns({
            tasks = {
                {
                    label = "lint",
                    type = "npm",
                    script = "lint",
                },
            },
        })

        pasync.util.block_on(function()
            local specs = source_tasksjson:get_specs(nil)

            eq({ "npm", "run", "lint" }, specs["lint"].cmd)
        end)
    end)

    it("reads from tasks.json: type = typescript", function()
        fs_mock.read_json_file.returns({
            tasks = {
                {
                    group = "build",
                    type = "typescript",
                },
            },
        })

        pasync.util.block_on(function()
            local specs = source_tasksjson:get_specs(nil)

            eq({ "tsc", "--project", "tsconfig.json" }, specs["Build"].cmd)
        end)
    end)

    it("reads from tasks.json: type = typescript with custom tsconfig", function()
        fs_mock.read_json_file.returns({
            tasks = {
                {
                    group = "build",
                    type = "typescript",
                    tsconfig = "custom_tsconfig.json",
                },
            },
        })

        pasync.util.block_on(function()
            local specs = source_tasksjson:get_specs(nil)

            eq({ "tsc", "--project", "custom_tsconfig.json" }, specs["Build"].cmd)
        end)
    end)

    it("reads from tasks.json: type = shell (no custom shell)", function()
        fs_mock.read_json_file.returns({
            tasks = {
                {
                    group = "build",
                    type = "shell",
                    command = "myscript.sh",
                    args = { "build" },
                },
            },
        })

        pasync.util.block_on(function()
            local specs = source_tasksjson:get_specs(nil)

            eq({ vim.env.SHELL or "bash", "'myscript.sh build'" }, specs["Build"].cmd)
        end)
    end)

    it("reads from tasks.json: type = shell (with custom shell)", function()
        fs_mock.read_json_file.returns({
            tasks = {
                {
                    group = "build",
                    type = "shell",
                    command = "ls",
                    args = { "-lah" },
                    shell = {
                        executable = "bash",
                        args = { "-c" },
                    },
                },
            },
        })

        pasync.util.block_on(function()
            local specs = source_tasksjson:get_specs(nil)

            eq({ "bash", "-c", "'ls -lah'" }, specs["Build"].cmd)
        end)
    end)

    it("silently fails on package.json read errors", function()
        fs_mock.read_json_file.invokes(function()
            assert(false, "error on ready package.json")
        end)

        pasync.util.block_on(function()
            local specs = source_tasksjson:get_specs(nil)

            eq(nil, specs)
            assert.stub(fs_mock.read_json_file).was_called_with(vim.loop.cwd() .. "/.vscode/tasks.json")
        end)
    end)

    it("sends tasks using the tx sender", function()
        fs_mock.read_json_file.returns({
            tasks = {
                {
                    label = "Run tests",
                    type = "shell",
                    command = "./scripts/test.sh",
                },
            },
        })

        pasync.util.block_on(function()
            local tx, rx = pasync.control.channel.oneshot()

            local specs = source_tasksjson:get_specs(tx)

            local rx_specs = rx()

            eq({ vim.env.SHELL or "bash", "'./scripts/test.sh'" }, specs["Run tests"].cmd)
            eq({ vim.env.SHELL or "bash", "'./scripts/test.sh'" }, rx_specs["Run tests"].cmd)
            assert.stub(fs_mock.read_json_file).was_called_with(vim.loop.cwd() .. "/.vscode/tasks.json")
        end)
    end)

    it("creates autocommands to reload package.json tasks", function()
        fs_mock.read_json_file.returns({
            tasks = {
                {
                    label = "Run tests",
                    type = "shell",
                    command = "./scripts/test.sh",
                },
            },
        })

        local cb_called = false

        local tx = function()
            cb_called = true
        end

        source_tasksjson:start_specs_listener(tx)

        assert.stub(api_mock.nvim_create_augroup).was_called_with("TasksNvimTasksJsonSource", { clear = true })
        assert.stub(api_mock.nvim_create_autocmd).was_called_with("BufWritePost", match._)
        local autocmd_opts = api_mock.nvim_create_autocmd.calls[1].vals[2]
        eq("TasksNvimTasksJsonSource", autocmd_opts.group)
        eq(".vscode/tasks.json", autocmd_opts.pattern[1])

        autocmd_opts.callback()

        eq(true, cb_called)
    end)
end)
