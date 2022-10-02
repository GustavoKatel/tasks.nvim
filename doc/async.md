# Async utils

This is a wrapper around `plenary.async` but with extra utilities.

## async.async_vim_wrap()

Similar to `plenary.async.wrap` but it combines with `vim.schedule` to call the callback in a safe environment for api calls.

```lua
local async = require("tasks.lib.async")

async.run(function()
    local fn = async.async_vim_wrap(function(fname)
        return vim.fn.fnamemodify(vim.fn.expand(fname))
    end)

    local ret = fn("%")

    print(ret)
end)
```

## async.fn.*()

It wraps every `vim.fn.*` function inside `async.async_vim_wrap` to it's easier to run in async contexts.

Example:

This is similar to the above example.

```lua
local async = require("tasks.lib.async")

async.run(function()
    local ret = async.fn.fnamemodify(async.fn.expand("%"))

    print(ret)
end)
```

## async.*

Everything else from `plenary.async` is available as well.
