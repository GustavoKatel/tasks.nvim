# Builtin Runner

The builtin runner has a few customization options.

## sticky_terminal_window

Default: `false`

This will make the runner remember which window it ran the first terminal task. All subsequent tasks will run in the same window number.

Example:

```
local runner_builtin = require("tasks.runners.builtin")

tasks.setup({
    ...
    runners = {
		builtin = runner_builtin:with({ sticky_terminal_window = true }),
	},
    ...
})
```

## terminal_edit_command

The vim command to open terminals.

Default: `edit`

Example:

This config will make all terminals open in a split instead of the current window (the default with `edit`).

```
local runner_builtin = require("tasks.runners.builtin")

tasks.setup({
    ...
    runners = {
		builtin = runner_builtin:with({ terminal_edit_command = "split" }),
	},
    ...
})
```
