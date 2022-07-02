# tasks.nvim

## setup

call `setup` is not mandatory

Example:

```lua
local tasks = require("tasks")

local source_npm = require("tasks.sources.npm")

local builtin = require("tasks.sources.builtin")

require("telescope").load_extension("tasks")

tasks.setup({
	sources = {
		npm = source_npm,
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

### tasks.json (vscode)

TODO

## Runners

### builtin

the builtin runner is a generic runner that allows you to run lua functions, vim commands or shell commands (using the terminal `:e term://...`)

it's always available.

### custom runners

a very minimal custom runner that runs lua functions (async functions) can be created as such:

```lua
tasks.setup({
    ...
    runners = {
        custom_runner = {
            create_task = function(self, spec, args)
                return Tasks:new(spec.fn, args)
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

## telescope integration

```
:Telescope tasks specs
```

## sidebar.nvim integration

```lua
local tasks_section = require("sidebar-nvim.sections.tasks")

local sidebar = require("sidebar-nvim")

sidebar.setup({
    ...
    sections = { tasks_section }
    ...
})
```
