# Source API

A source is a spec generator. It is responsible for contributing specs that can be converted into [Tasks](./task.md) by [Runners](./runner.md)

See [Spec](./spec.md) for the Spec specification that all sources and runners should follow.

## Source:create()

Create a new source inheriting from the base.

It already implements a generic `get_specs` method.

Example:

```lua
local Source = require("tasks.lib.source")
local source = Source:create({
    specs = { my_spec1 = { vim_cmd = "echo 'ok'" } },
    custom_option_1 = true,
})

eq(true, source.custom_option_1)
```

## Source:create_from_source_file()

Similar to `Source:create` but provides helpers to read, parse and watch a certain file contents so it can update the specs.

It already implements a `get_specs` with some helpers.
It already creates the necessary [reloaders](./reloaders.md) and [conditions](./conditions.md).

Example:

> *Note*
> See [fs](./fs.md)

```lua
local fs = require("tasks.lib.fs")

local source = Source:create_from_source_file({
    filename = "package.json",
    reader = fs.read_json_file,
    parser = function(self, json_obj)
        local specs = {}

        local scripts = json_obj["scripts"] or {}

        for name, _ in pairs(scripts) do
            specs[name] = {
                cmd = {"npm", "run", name},
            }
        end

        return specs
    end
})
```

## Source:get_specs()

This is the core method of each source. It returns all the specs that this source provides.

Example:

```lua
local custom_source = Source:create()

function custom_source:get_specs()
    return {
        test = {
            cmd = { "make", "test" }
        },
        build = {
            cmd = { "make", "build" }
        }
    }
end

return custom_source
```

## Source.conditions = {}

Before collecting specs with `get_specs`, `tasks.nvim` will check each one of these conditions, if at least one of them returns `false`, this means that this source don't have enough requirements to create specs. There are some available `condition` checks that can be reused. Check [conditions](./conditions.md)

Example:

```lua
local conditions = require("tasks.lib.conditions")

local custom_source = Source:create({
    conditions = { conditions.file_exists("Makefile") },
    specs = {
        build = { cmd = { "make", "build" } }
    }
})
```

## Source.reloaders = {}

`tasks.nvim` will take care of keeping the source updated based on the reloaders list. Each source can define any number of reloaders. There are some available `reloaders` that can be reused. Check [reloaders](./reloaders.md)

> *Note*
> if you're using `Source:create_from_source_file` this will be already set for you.

Example:

```lua
local reloaders = require("tasks.lib.conditions")

local custom_source = Source:create({
    reloaders = { reloaders.file_changed("package.json") },
    -- get specs will be called every time "package.json" changes
    get_specs = function(self)
        local package_json = fs.read_json_file("package.json")
        
        return package_json_to_specs(package_json)
    end
})
```

## Source:with()

A helper to allow users to easily override source options while creating a new one.

Example:

```lua
local my_source = Source:create({
    specs = {
        spec1 = {
            cmd = { "echo", "test1" }
        }
    }
})

local new_source = my_source:with({
    specs = {
        spec1 = {
            cmd = { "echo", "test2" }
        }
    }
})
```

