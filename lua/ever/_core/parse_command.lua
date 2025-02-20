local M = {}

--- Expand `%` to current file
---@param cmd string
---@return string
M.parse = function(cmd)
    return cmd
end

local pattern = '"(.*?)"'
local non_quoted = "git log --follow %"
local quoted = "git grep '%'"

vim.print("non_quoted", non_quoted:match(pattern))
vim.print("quoted", quoted:match(pattern))

return M
