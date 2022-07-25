# Filesystem utils

## fs.read_file()

Async read files using libuv. See [async](./async.md)

Example:

```lua
local fs = require("tasks.lib.fs")

local data = fs.read_file("my_file.txt")

print(data)
```

## fs.read_json_file()

Async read and parse json files.

It combines `fs.read_file` with `vim.json.decode()`.

Example:

```lua
local fs = require("tasks.lib.fs")

local package = fs.read_json_file("package.json")

print(package)
```
