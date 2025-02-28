---@class ever.GrepQflistItem
---@field bufnr integer
---@field lnum integer
---@field col integer

local M = {}

---@param cmd string
local function add_grep_flags(cmd)
    return "git grep -n --column " .. cmd:gsub(".*grep%s", "")
end

---@param bufnr integer
---@param line string
---@return ever.GrepQflistItem
function M._create_grep_qflist_item(bufnr, line)
    local first_colon = line:find(":")
    local second_colon = line:find(":", first_colon + 1)
    local third_colon = line:find(":", second_colon + 1)
    return {
        bufnr = bufnr,
        lnum = tonumber(line:match("%d+", second_colon + 1)),
        col = tonumber(line:match("%d+", third_colon + 1)),
    }
end

---@param cmd string
function M.render(cmd)
    print(add_grep_flags(cmd))
end

return M
