# Utils

## replace_variables(arg, inputs_def)

Substitute all variables in the string `arg`.

Pass a table `inputs_def` with inputs definitions. Inputs required in `arg` will be translated into `vim.ui.*` inputs so the user can populate its value.

Variables and Inputs specification follow the `tasks.json` specification here: https://code.visualstudio.com/docs/editor/variables-reference and https://code.visualstudio.com/docs/editor/variables-reference#_input-variables

Examples:

```lua
local ret = utils.replace_variables("${env:HOME}${pathSeparator}script.sh ${file}")
eq(vim.fn.expand("$HOME") .. "/script.sh /tmp/test.txt", ret)
```

```lua
local ret = utils.replace_variables(
    "${env:HOME}${pathSeparator}script.sh ${input:scriptName}",
    {
        {
            type = "pickString",
            id = "scriptName",
            description = "Select script name",
            options = { "/tmp/test.txt", "/tmp/test2.txt" },
        },
    }
)

-- user will be prompted with `vim.ui.select` and `${input:scriptName}` will be replace with the chosen value. For this example, let's say the user selected "/tmp/test.txt"

-- the result would be
eq(vim.fn.expand("$HOME") .. "/script.sh /tmp/test.txt", ret)
```
