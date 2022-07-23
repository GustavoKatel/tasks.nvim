# Runner API

All runners should extend this base table.

## Runner:create_task()

This is the core of the runner. It receives a spec and returns a task ready to be run. See [Task](./task.md)

Example:

```lua
local Runner = require("tasks.lib.runner")

local custom_runner = Runner:create({ custom_message_1 = "hello", custom_message_2 = "done!" })

function custom_runner:create_task(spec, args, runner_opts)
    local fn = function(ctx, args)
        print(self.custom_message_1)

        -- run the spec fn
        local ret = spec.fn(args)

        -- check if the user passed custom options to this runner
        if self.runner_opts ~= nil then
            print(self.runner_opts.user_message)
        end

        print(self.custom_message_2)

        return ret
    end
    return Task:create(fn)
end
```

Please refer to `replace_variables` in [utils](./utils.md) to see how to integrate variable substitution to your runner.

## Runner:create()

Create a new runner with default options

Example:

```lua
local Runner = require("tasks.lib.runner")

local custom_runner = Runner:create()
```

## Runner:with()

A helper to allow users to easily override runner options while creating a new one.

Example:

```lua
local Runner = require("tasks.lib.runner")

local custom_runner = Runner:create({ custom_message_1 = "hello", custom_message_2 = "done!" })

function custom_runner:create_task(spec, args, runner_opts)
    local fn = function(ctx, args)
        print(self.custom_message_1)

        -- run the spec fn
        local ret = spec.fn(args)

        -- check if the user passed custom options to this runner
        if self.runner_opts ~= nil then
            print(self.runner_opts.user_message)
        end

        print(self.custom_message_2)

        return ret
    end
    return Task:create(fn)
end

local custom_runner_2 = custom_runner:with({ custom_message_1 = "hi" })
```

In the example, `custom_runner_2` will print "hi" before running tasks instead of "hello" as defined by `custom_message_1`.
