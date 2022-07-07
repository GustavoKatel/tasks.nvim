local Source = require("tasks.lib.source")
local conditions = require("tasks.lib.conditions")

return Source:create({
    conditions = {
        conditions.file_exists("Cargo.toml"),
    },
    specs = {
        run = {
            cmd = { "cargo", "run" },
        },
        watch = {
            cmd = { "cargo", "watch" },
        },
        test = {
            cmd = { "cargo", "test" },
        },
    },
})
