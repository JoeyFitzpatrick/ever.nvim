local M = {}

---@param lines string[]
---@param strategy "base" | "ours" | "theirs" | "all"
function M.resolve_merge_conflict(lines, strategy)
    local result = {}
    local section = "none"
    local base_content = {}
    local ours_content = {}
    local theirs_content = {}

    for _, line in ipairs(lines) do
        if line:match("^<<<<<<< HEAD") then
            section = "ours"
        elseif line:match("^||||||| ") then
            section = "base"
        elseif line:match("^=======") then
            section = "theirs"
        elseif line:match("^>>>>>>> ") then
            section = "none"
        else
            if section == "base" then
                table.insert(base_content, line)
            elseif section == "ours" then
                table.insert(ours_content, line)
            elseif section == "theirs" then
                table.insert(theirs_content, line)
            end

            if strategy == "all" then
                table.insert(result, line)
            end
        end
    end

    if strategy == "base" then
        return base_content
    elseif strategy == "ours" then
        return ours_content
    elseif strategy == "theirs" then
        return theirs_content
    elseif strategy == "all" then
        return result
    else
        error("Invalid strategy. Use 'base', 'ours', 'theirs', or 'all'.")
    end
end

return M
