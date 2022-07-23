local fs = require("tasks.lib.fs")
local reloaders = require("tasks.lib.reloaders")
local conditions = require("tasks.lib.conditions")

local Source = { conditions = {}, reloaders = {}, specs = {} }

Source.__index = Source

function Source:create(opts)
    opts = vim.tbl_extend("force", self, opts or {})

    local obj = setmetatable(opts, self)

    return obj
end

function Source:create_from_source_file(opts)
    opts = opts or { filename = nil, reader = fs.read_file, parser = nil }

    local obj = self:create(vim.tbl_extend("force", opts, {
        conditions = {
            conditions.file_exists("Cargo.toml"),
        },
        reloaders = { reloaders.file_changed(opts.filename), unpack(opts.reloaders or {}) },
        get_specs = function(s)
            local ok, data = pcall(s.reader, s.filename)
            assert(ok, { message = "failed to read/parse file: " .. s.filename, internal = data })

            local specs = s:parser(data)

            return specs
        end,

        with = Source.create_from_source_file,
    }))

    return obj
end

function Source:with(opts_overrides)
    return self:create(opts_overrides)
end

function Source:get_specs()
    return self.specs
end

function Source:verify_conditions()
    for _, condition in ipairs(self.conditions or {}) do
        if not condition() then
            return false
        end
    end

    return true
end

return Source
