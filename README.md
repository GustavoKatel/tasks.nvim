# tasks.nvim

## State

Alpha

Dependencies:

- https://github.com/nvim-lua/plenary.nvim

Neovim versions:

- `0.7.2`
- `nightly`

## Installation

With Packer:

```lua
use({ "GustavoKatel/tasks.nvim", requires = { "nvim-lua/plenary.nvim" } })
```

## Configuration

Calling `setup` is not mandatory

Example:

```lua
local tasks = require("tasks")

local source_npm = require("tasks.sources.npm")
local source_tasksjson = require("tasks.sources.tasksjson")

local builtin = require("tasks.sources.builtin")

require("telescope").load_extension("tasks")

tasks.setup({
	sources = {
		npm = source_npm,
		vscode = source_tasksjson,
		utils = builtin.new_builtin_source({
			sleep = {
				fn = function(ctx)
					local pasync = require("plenary.async")

					pasync.util.sleep(10000)
				end,
			},

            vim_cmd = {
                vcmd = "echo 'ok'"
            },

            shell_cmd = {
                cmd = "make test"
            }
		}),
	},
})

```

## Sources

### builtin

the builtin source is just a place holder to allow you to define custom task specs using lua functions, vim commands or shell commands.

### npm

It will load all `package.json` scripts from the project root to be used as task specs.

### tasksjson (vscode)

It will load all tasks from `.vscode/tasks.json` to be used as task specs.

There are bunch of things missing from the schema, I believe it's enough to get started. Please open an issue if you think any of the missing features should be added.

## Runners

### builtin

The builtin runner is a generic runner that allows you to run lua functions, vim commands or shell commands (using the terminal `:e term://...`)

It's always available, even if you don't specify in your config.

### Custom runners

A very minimal custom runner that runs lua functions (async functions) can be created as such:

```lua
local Task = require("tasks.lib.task")
local tasks = require("tasks")

tasks.setup({
    ...
    runners = {
        custom_runner = {
            create_task = function(self, spec, args)
                return Task:new(spec.fn, args)
            end
        }
    },

    sources = {
        my_tasks = builtin.new_builtin_source({
			sleep = {
				fn = function(ctx)
					local pasync = require("plenary.async")

					pasync.util.sleep(10000)
				end,
                -- this prop will route this task to the custom runner
                runner_name = "custom_runner"
			},
		}),
    }
})
```

### Custom router

You can specify a router function to better match specs with runners. This will override the `runner_name` in the specs.

```lua
tasks.setup({
    runners = { ... },
    sources = { ... },
    router = function(spec_name, spec, args, source_name)
        -- this will run all specs from the `npm` source in runner with name `my_custom_runner`
        if source_name == "npm" then
            return "my_custom_runner"
        end
        return nil -- fallback to use the default router value
    end
})
```

## Integrations

### Telescope

```
:Telescope tasks specs
```

Shows all the available specs from all sources.

The default action will create and run a new task.

![telescope-demo](./demo/telescope_demo_specs.png)

```
:Telescope tasks running
```

Shows all current running tasks.

The default action will request the task to stop (call `task:request_stop()`).

![telescope-demo](./demo/telescope_demo_running.png)

### sidebar.nvim integration

```lua
local tasks_section = require("sidebar-nvim.sections.tasks")

local sidebar = require("sidebar-nvim")

sidebar.setup({
    ...
    sections = { tasks_section }
    ...
})
```

![sidebar-demo](./demo/sidebar_demo.png)

### statusline/tabline/winbar

Minimal integration for lualine

```lua
lualine.setup({
    ...
    sections = {
        lualine_c = {
            require("tasks.statusline.running")("<custom_icon or prefix>")
        }
    }
    ...
})
```

## API

### tasks.run(spec_name, args, source_name)

Run the first spec with name `spec_name` additionally passing extra args in `args`

You can also pass `source_name` to refine the search and only run specs from that source.

Returns `task_id` and a task table ([Task](#task-api))

### tasks.run_last()

Re-run the last spec with the same args passed in the last call to `tasks.run`

Returns `task_id` and task table

### tasks.get_specs({ source_name = nil, runner_name = nil })

Get all the available specs. Optionally filter by spec name `spec_name` and runner name `runner_name`.

Returns dictionary

Example of return value:

```lua
{
    ["my_source"] = {
        ["spec_1"] = {
            ...
        },
        ["spec_2"] = {
            ...
        }
    },
    [<source_name>] = {
        [<spec_name>] = <spec>
    }
}
```

### tasks.get_running_tasks({ source_name = nil, runner_name = nil })

Get all the tasks currently running. Optionally filter by spec name `spec_name` and runner name `runner_name`.

Returns dictionary

Example of return value:

```lua
{
    [1] = <task>,
    [2] = <task>,
    ...
    [<task_id>] = <task>
}
```

### task api

A task object has a few helper methods.

### task:get_spec_name()

### task:get_source_name()

### task:get_runner_name()

### task:get_state()

Returns the current task state, which can evolve from `ready` -> `running` -> `done`.

### task:request_stop()

Signal the underlying job that this task should be cancelled.

### task:get_started_time()

### task:get_finished_time()
