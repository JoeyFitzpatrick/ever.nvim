local M = {}

--- Given a list of files, return true if all files should be staged,
--- and false otherwise.
--- This returns true if any of the given files are not staged.
---@param files string[]
---@return boolean
function M.should_stage_files(files)
    for _, file in ipairs(files) do
        if file:match("^.%S") then
            return true
        end
    end
    return false
end

return M
