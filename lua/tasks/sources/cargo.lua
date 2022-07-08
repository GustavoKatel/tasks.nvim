local Source = require("tasks.lib.source")
local conditions = require("tasks.lib.conditions")

-- inspired by https://gist.github.com/yngwi/5df0c45afff0bf79e7e100d53f49eaa2

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
