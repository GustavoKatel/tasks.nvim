local fs = require("tasks.lib.fs")
local Source = require("tasks.lib.source")

return Source:create_from_source_file({
    script_runner = { "npm", "run" },
    filename = "package.json",
    reader = fs.read_json_file,
    parser = function(self, package)
        local specs = {}

        local scripts = package["scripts"] or {}

        for name, _ in pairs(scripts) do
            specs[name] = {
                cmd = vim.tbl_flatten({ self.script_runner, name }),
                cwd = vim.loop.cwd(),
                env = {},
            }
        end

        return specs
    end,
})

--return M
