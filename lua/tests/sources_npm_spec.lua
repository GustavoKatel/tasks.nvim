local pasync = require("plenary.async")
local mock = require("luassert.mock")
local match = require("luassert.match")
local source_npm = require("tasks.sources.npm")
local fs = require("tasks.lib.fs")

local eq = assert.are.same

describe("source npm tests", function()
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

    it("reads from root package.json", function()
        fs_mock.read_json_file.returns({ scripts = { my_script = "jest" } })

        pasync.util.block_on(function()
            local specs = source_npm:get_specs(nil)

            eq("jest", specs.my_script.cmd)
        end)
    end)

    it("silently fails on package.json read errors", function()
        fs_mock.read_json_file.invokes(function()
            assert(false, "error on ready package.json")
        end)

        pasync.util.block_on(function()
            local specs = source_npm:get_specs(nil)

            eq(nil, specs)
            assert.stub(fs_mock.read_json_file).was_called_with(vim.loop.cwd() .. "/package.json")
        end)
    end)

    it("sends tasks using the tx sender", function()
        fs_mock.read_json_file.returns({ scripts = { my_script = "jest" } })

        pasync.util.block_on(function()
            local tx, rx = pasync.control.channel.oneshot()

            local specs = source_npm:get_specs(tx)

            local rx_specs = rx()

            eq("jest", specs.my_script.cmd)
            eq("jest", rx_specs.my_script.cmd)
            assert.stub(fs_mock.read_json_file).was_called_with(vim.loop.cwd() .. "/package.json")
        end)
    end)

    it("creates autocommands to reload package.json tasks", function()
        fs_mock.read_json_file.returns({ scripts = { my_script = "jest" } })

        local cb_called = false

        local tx = function()
            cb_called = true
        end

        source_npm:start_specs_listener(tx)

        assert.stub(api_mock.nvim_create_augroup).was_called_with("TasksNvimNpmSource", { clear = true })
        assert.stub(api_mock.nvim_create_autocmd).was_called_with("BufWritePost", match._)
        local autocmd_opts = api_mock.nvim_create_autocmd.calls[1].vals[2]
        eq("TasksNvimNpmSource", autocmd_opts.group)
        eq("package.json", autocmd_opts.pattern[1])

        autocmd_opts.callback()

        eq(true, cb_called)
    end)
end)
