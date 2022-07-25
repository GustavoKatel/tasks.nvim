local M = {}

function M.autocmd(event_name, pattern)
    return { event_name = event_name, pattern = pattern }
end

function M.file_changed(file_list)
    return M.autocmd("BufWritePost", vim.tbl_flatten({ file_list }))
end

return M
