# Reloaders

Helpers that can automatically trigger a [Source](./source.md) reload.

Use this to avoid polling on the inner source of your [Source](./source.md), like a file or user event.

## reloaders.file_changed()

This will create a reloader that is triggered when the user changed any of the files passed in as parameters.

Example:

```lua
local reloaders = require("tasks.lib.reloaders")

local source = Source:create({
    reloaders = { reloaders.file_changed(".nvim/tasks.json") },
    get_specs = function(self)
        local json = fs.read_json_file(".nvim/tasks.json")

        return nvim_tasks_to_specs(json)
    end
})
```

In the example, `.nvim/tasks.json` will be sourced every time the user changes it. This uses `BufWritePost` in the underlying event.

## reloaders.autocmd()

This creates a generic reloader using autocommands.

Example:

```lua
local reloaders = require("tasks.lib.reloaders")

local source = Source:create({
    reloaders = { reloaders.autocmd("User", "MyCustomEvent") },
    get_specs = function(self)
        local specs = fetch_specs_from_somewhere()

        return specs
    end
})
```
