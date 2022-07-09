local source_tasksjson = require("tasks.sources.tasksjson")

local eq = assert.are.same

describe("tasksjson tests", function()
    it("reads from tasks.json", function()
        local specs = source_tasksjson:parser({
            tasks = {
                {
                    label = "Run tests",
                    type = "process",
                    command = "./scripts/test.sh",
                },
            },
        })

        eq({ "./scripts/test.sh" }, specs["Run tests"].cmd)
    end)

    it("reads from tasks.json: without label", function()
        local specs = source_tasksjson:parser({
            tasks = {
                {
                    command = "./scripts/test.sh",
                },
            },
        })

        eq({ "./scripts/test.sh" }, specs["task 1"].cmd)
    end)

    it("reads from tasks.json: without label and with group (test)", function()
        local specs = source_tasksjson:parser({
            tasks = {
                {
                    command = "./scripts/test.sh",
                    group = "test",
                },
            },
        })

        eq({ "./scripts/test.sh" }, specs["Test"].cmd)
    end)

    it("reads from tasks.json: without label and with group (build)", function()
        local specs = source_tasksjson:parser({
            tasks = {
                {
                    command = "./scripts/test.sh",
                    group = "build",
                },
            },
        })

        eq({ "./scripts/test.sh" }, specs["Build"].cmd)
    end)

    it("reads from tasks.json: without label and with group (test kind)", function()
        local specs = source_tasksjson:parser({
            tasks = {
                {
                    command = "./scripts/test.sh",
                    group = {
                        kind = "test",
                    },
                },
            },
        })

        eq({ "./scripts/test.sh" }, specs["Test"].cmd)
    end)

    it("reads from tasks.json: npm script", function()
        local specs = source_tasksjson:parser({
            tasks = {
                {
                    label = "lint",
                    type = "npm",
                    script = "lint",
                },
            },
        })

        eq({ "npm", "run", "lint" }, specs["lint"].cmd)
    end)

    it("reads from tasks.json: type = typescript", function()
        local specs = source_tasksjson:parser({
            tasks = {
                {
                    group = "build",
                    type = "typescript",
                },
            },
        })

        eq({ "tsc", "--project", "tsconfig.json" }, specs["Build"].cmd)
    end)

    it("reads from tasks.json: type = typescript with custom tsconfig", function()
        local specs = source_tasksjson:parser({
            tasks = {
                {
                    group = "build",
                    type = "typescript",
                    tsconfig = "custom_tsconfig.json",
                },
            },
        })

        eq({ "tsc", "--project", "custom_tsconfig.json" }, specs["Build"].cmd)
    end)

    it("reads from tasks.json: type = shell (no custom shell)", function()
        local specs = source_tasksjson:parser({
            tasks = {
                {
                    group = "build",
                    type = "shell",
                    command = "myscript.sh",
                    args = { "build" },
                },
            },
        })

        eq({ vim.env.SHELL or "bash", "'myscript.sh build'" }, specs["Build"].cmd)
    end)

    it("reads from tasks.json: type = shell (with custom shell)", function()
        local specs = source_tasksjson:parser({
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

        eq({ "bash", "-c", "'ls -lah'" }, specs["Build"].cmd)
    end)

    it("attaches inputs to the specs", function()
        local specs = source_tasksjson:parser({
            inputs = { { id = "file", description = "enter file name" } },
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

        eq({ { id = "file", description = "enter file name" } }, specs["Build"].inputs)
    end)
end)
