local Path = require("plenary.path")
local pasync = require("tasks.lib.async")
local mock = require("luassert.mock")

local utils = require("tasks.utils")

local eq = assert.are.same

describe("utils tests", function()
    local ui_mock

    before_each(function()
        vim.cmd("edit /tmp/test.txt")
        vim.api.nvim_buf_set_lines(0, 0, 0, false, { "test" })

        ui_mock = mock(vim.ui, true)
    end)

    after_each(function()
        vim.cmd("bdelete!")

        mock.revert(ui_mock)
    end)

    it("replaces variables", function()
        local ret = utils.replace_variables("${userHome}${pathSeparator}script.sh ${file}")

        eq(vim.fn.expand("$HOME") .. Path.path.sep .. "script.sh /tmp/test.txt", ret)
    end)

    it("replaces variables: env", function()
        local ret = utils.replace_variables("${env:HOME}${pathSeparator}script.sh ${file}")

        eq(vim.fn.expand("$HOME") .. Path.path.sep .. "script.sh /tmp/test.txt", ret)
    end)

    it("replaces with inputs: pickString", function()
        pasync.util.block_on(function()
            ui_mock.select.invokes(function(items, opts, cb)
                eq({ "/tmp/test.txt", "/tmp/test2.txt" }, items)
                eq({ prompt = "Select script name" }, opts)

                cb("/tmp/test.txt")
            end)

            local ret = utils.replace_variables("${env:HOME}${pathSeparator}script.sh ${input:scriptName}", {
                {
                    type = "pickString",
                    id = "scriptName",
                    description = "Select script name",
                    options = { "/tmp/test.txt", "/tmp/test2.txt" },
                },
            })

            assert.stub(ui_mock.select).was.called()
            eq(vim.fn.expand("$HOME") .. Path.path.sep .. "script.sh /tmp/test.txt", ret)
        end)
    end)

    it("replaces with inputs: promptString", function()
        pasync.util.block_on(function()
            ui_mock.input.invokes(function(opts, cb)
                eq({ prompt = "Enter script name" }, opts)

                cb("/tmp/test.txt")
            end)

            local ret = utils.replace_variables("${env:HOME}${pathSeparator}script.sh ${input:scriptName}", {
                {
                    type = "promptString",
                    id = "scriptName",
                    description = "Enter script name",
                },
            })

            assert.stub(ui_mock.input).was.called()
            eq(vim.fn.expand("$HOME") .. Path.path.sep .. "script.sh /tmp/test.txt", ret)
        end)
    end)
end)
