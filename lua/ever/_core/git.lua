local M = {}

--- Returns true for a git status that represents a staged file, and false otherwise.
---@param status string
---@return boolean
M.is_staged = function(status)
    return vim.tbl_contains(require("ever._constants.git_status").STAGED_STATUSES, status)
end

--- Returns true for a git status that represents a modified file, and false otherwise.
---@param status string
---@return boolean
M.is_modified = function(status)
    return vim.tbl_contains(require("ever._constants.git_status").MODIFIED_STATUSES, status)
end

--- Returns true for a git status that represents a deleted file, and false otherwise.
---@param status string
---@return boolean
M.is_deleted = function(status)
    return vim.tbl_contains(require("ever._constants.git_status").DELETED_STATUSES, status)
end

--- Returns true for a git status that represents a deleted file, and false otherwise.
---@param status string
---@return boolean
M.is_renamed = function(status)
    return vim.tbl_contains(require("ever._constants.git_status").RENAMED_STATUSES, status)
end

return M
