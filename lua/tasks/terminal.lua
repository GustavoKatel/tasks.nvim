local pasync = require("tasks.lib.async")

local M = {}

function M.create_terminal_job(window_nr, cmd, opts)
    local job_id
    local term_id

    job_id = pasync.fn.jobstart(cmd, {
        pty = true,
        -- env = opts.env,
        cwd = opts.cwd,
        on_stdout = function(_, data)
            if not term_id then
                return
            end

            for i, bytes in ipairs(data) do
                vim.api.nvim_chan_send(term_id, bytes)

                if i > 1 then
                    vim.api.nvim_chan_send(term_id, "\n")
                end
            end
        end,
        on_exit = function(job_id_from_cb, code)
            job_id = nil
            if opts.on_exit then
                opts.on_exit(job_id_from_cb, code)
            end

            vim.api.nvim_chan_send(term_id, "task finished! Job code: " .. code)
        end,
    })

    local bufnr = vim.api.nvim_create_buf(false, false)

    vim.api.nvim_buf_set_name(bufnr, opts.buf_name or "[task]")

    pasync.api.nvim_win_set_buf(window_nr, bufnr)

    term_id = vim.api.nvim_open_term(bufnr, {
        on_input = function(_input, _term, _bufnr, data)
            if not job_id then
                return
            end

            vim.api.nvim_chan_send(job_id, data)
        end,
    })

    return {
        bufnr = bufnr,
        job_id = job_id,
        term_id = term_id,
    }
end

return M
