local M = {}

function M.file_exists(filename)
    return function()
        return vim.fn.filereadable(vim.fn.expand(filename)) == 1
    end
end

return M
