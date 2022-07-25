-- based on https://www.reddit.com/r/neovim/comments/t88al5/using_treesitter_api_to_remove_comments_in_a/

local pasync = require("tasks.lib.async")

local M = {}

function M.jsonc_no_comment(content)
    local parser = vim.treesitter.get_string_parser(content, "jsonc")
    local tree = parser:parse()
    local root = tree[1]:root()
    -- create comment query
    local query = vim.treesitter.parse_query("jsonc", "((comment) @c (#offset! @c))")
    -- split content lines
    local lines = vim.split(content, "\n")
    -- iterate over query match metadata
    for _, _, metadata in query:iter_matches(root, content, root:start(), root:end_()) do
        local region = metadata.content[1]
        local line = region[1] + 1
        local col_start = region[2]
        -- remove comment by extracting the text before
        lines[line] = string.sub(lines[line], 1, col_start)
    end
    -- join lines
    local result = table.concat(lines, "\n")
    return result
end

function M.jsonc_no_trailing_comma(content)
    return string.gsub(content or "", ",%s*}", "")
end

function M.jsonc_to_json(content)
    content = M.jsonc_no_trailing_comma(content)
    content = M.jsonc_no_comment(content)
    return content
end

function M.decode(content)
    local clean_content = M.jsonc_to_json(content)
    return vim.json.decode(clean_content)
end

M.decode_async = pasync.async_vim_wrap(M.decode)

return M
