local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
    error("tasks.nvim requires nvim-telescope/telescope.nvim")
end

return telescope.register_extension({
    exports = {
        specs = require("telescope._extensions.tasks.specs"),
    },
})
