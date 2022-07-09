local Path = require("plenary.path")
local pasync = require("tasks.lib.async")

local M = {}

function M.assert_err(...)
    local err, ret = ...
    assert(not err, err)

    return ret
end

-- inpired by https://gitlab.com/jrop/dotfiles/-/blob/master/.config/nvim/lua/my/utils.lua#L13
-- and https://www.reddit.com/r/neovim/comments/vu9atg/how_do_i_get_the_text_selected_in_visual_mode/
function M.get_selected_text()
    local vstart = vim.fn.getpos("'<") -- [bufnum, lnum, col, off]

    local vend = vim.fn.getpos("'>")

    local lines = vim.fn.getline(vstart[2], vend[2])

    local cstart = vstart[3]
    local cend = vend[3]

    if #lines == 0 then
        return {}
    end

    if #lines == 1 then
        cend = cend - cstart + 1
    end

    lines[1] = string.sub(lines[1], cstart)
    lines[#lines] = string.sub(lines[#lines], 0, cend)

    return lines
end

function M.replace_variables(arg, inputs)
    local cursor = vim.api.nvim_win_get_cursor(0)

    local selected_text = table.concat(M.get_selected_text(), "\n")

    local vars = {
        ["userHome"] = vim.fn.expand("$HOME"),
        ["workspaceFolder"] = vim.loop.cwd(),
        ["workspaceFolderBasename"] = vim.loop.cwd(),
        ["cwd"] = vim.loop.cwd(),
        ["file"] = vim.fn.expand("%:p"),
        ["fileWorkspaceFolder"] = vim.fn.expand("%:p:h"),
        ["relativeFileDirname"] = vim.fn.expand("%:.:h"),
        ["fileBasename"] = vim.fn.expand("%:t"),
        ["fileBasenameNoExtension"] = vim.fn.expand("%:t:r"),
        ["fileExtname"] = vim.fn.expand("%:t:e"),
        ["fileDirname"] = vim.fn.expand("%:p:h"),
        ["lineNumber"] = cursor[1],
        ["selectedText"] = selected_text,
        ["execPath"] = "",
        ["pathSeparator"] = Path.path.sep,
    }

    local inputs_values = {}
    for input_id in arg:gmatch("${input:(%w+)}") do
        inputs_values[input_id] = M.get_input(inputs, input_id) or ""
    end

    arg = string.gsub(arg, "${([:%w]+)}", function(var)
        local env = var:gmatch("env:(%w+)")()
        if env ~= nil then
            return vim.env[env]
        end

        local input_id = var:gmatch("input:(%w+)")()
        if input_id ~= nil then
            return inputs_values[input_id]
        end

        return vars[var] or string.format("${%s}", var)
    end)

    return arg
end

function M.build_prompt(input)
    if input.type == "pickString" then
        return function(cb)
            vim.ui.select(input.options or {}, { prompt = input.description }, cb)
        end
    end

    return function(cb)
        vim.ui.input({ prompt = input.description }, cb)
    end
end

function M.get_input(inputs, id)
    for _, input in ipairs(inputs or {}) do
        if input.id == id then
            return pasync.wrap(M.build_prompt(input), 1)()
        end
    end

    return nil
end

return M
