# Conditions helpers

Helpers ready to be used in [Sources](./source.md).

Use this to enable/disable sources based on requirements.

## conditions.file_exists()

Returns `true` or `false` based on the existence of the specified file.

Example:

```lua
local conditions = require("tasks.lib.conditions")

local source = Source:create({
    conditions = { conditions.file_exists("Cargo.toml") }
    specs = {
        build = { cmd = { "cargo", "build" } }
    }
})
```

In the example, the spec "build" will only be available if there's a `Cargo.toml` file.

## conditions.has_module()

Returns `true` or `false` based on the existence of the specified lua module.

Example:

```lua
local conditions = require("tasks.lib.conditions")

local source = Source:create({
    conditions = { conditions.has_module("dap") }
    specs = {
        ...
    }
})
```

In the example, the source will only provide specs if there's a `dap` module available using `require`.
