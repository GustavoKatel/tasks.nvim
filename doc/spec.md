# Spec API

When creating a [Source](./source.md) or a [Runner](./runner.md), please follow this specification of `Spec` attributes. If you find that there's should be a common/known attribute that can be reused by other sources and runners, feel free to open an issue or pull request to update this doc.

```lua
local spec = {
    -- terminal commands
    cmd = { "ls", "-lah" },

    -- vim commands
    vim_cmd = { "vsplit", "my_file.txt" },

    -- lua functions
    fn = function(ctx, args)
    end,

    -- current working directory used by terminal commands (cmd)
    cwd = "$HOME",

    -- extra environment variables passed to terminal commands (cmd)
    env = { ["PYTHON_PATH"] = "venv" },

    -- defines a list of dependencies for this spec, once all the specs defined in this list are finished, this spec will start.
    dependencies = { { spec_name = "build", args = {}, source_name = nil, dep.runner_opts = {} } },

    -- other attributes can be added, but they are not expected to be present
    ...
}
```

## Variables and Inputs

You are free to use variables and inputs in the specs definitions. Runners should be able to handle them using the helper `utils.replace_variables`.

Variables and Inputs specification follow the `tasks.json` specification here: https://code.visualstudio.com/docs/editor/variables-reference
