local fs = require("tasks.lib.fs")
local Source = require("tasks.lib.source")
local Path = require("plenary.path")
local pasync = require("tasks.lib.async")

return Source:create_from_source_file({
    script_runner = { "npm", "run" },
    filename = "package.json",
    reader = fs.read_json_file,
    parser = function(self, package)
        local specs = {}

        local cwd = Path:new(vim.loop.cwd())
        local package_path = pasync.fn.fnamemodify(self.filename, ":h")

        cwd = cwd / package_path

        local scripts = package["scripts"] or {}

        for name, _ in pairs(scripts) do
            specs[name] = {
                cmd = vim.tbl_flatten({ self.script_runner, name }),
                cwd = cwd.filename,
                env = {},
            }
        end

        return specs
    end,
})

--return M
