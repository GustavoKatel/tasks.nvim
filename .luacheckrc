-- vim: ft=lua tw=80

-- Rerun tests only if their modification time changed.
cache = true

std = luajit
codes = true

-- Don't report unused self arguments of methods.
self = false

ignore = {}

-- Global objects defined by the C code
globals = {
    "vim",
}
