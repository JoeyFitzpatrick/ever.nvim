---@class ever.SplitDiffParams
---@field filepath string
---@field commit string

-- Vdiff and Hdiff are 5 characters, plus a space
local SUBCOMMAND_LENGTH = 6

local M = {}

---@param cmd string
---@return ever.SplitDiffParams
local function parse_split_diff_args(cmd)
    local args = cmd:sub(SUBCOMMAND_LENGTH)
    local commit_hash = args:match("%x+")
    if not commit_hash then
        return { filepath = vim.fn.expand("%"), commit = "HEAD" }
    end
    return { filepath = vim.fn.expand("%"), commit = commit_hash }
end

---@param args string
---@param split_type "below" | "right"
function M.split_diff(args, split_type)
    local params = parse_split_diff_args(args)

    vim.cmd("diffthis")
    require("ever._core.open_file").open_file_in_split(params.filepath, params.commit, split_type)
    vim.cmd("diffthis")
end

return M
