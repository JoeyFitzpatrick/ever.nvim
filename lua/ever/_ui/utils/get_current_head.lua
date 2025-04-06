local M = {}

--- If no command is passed in, return the current branch.
--- Otherwise, parse the branch from the command passed in.
--- Includes handling for detached HEAD and errors.
---@param cmd string?
---@return string
function M.get_current_head(cmd)
    if cmd then
        local branch = require("ever._core.texter").find_non_dash_arg(cmd:sub(5))
        if branch then
            return "Branch: " .. branch
        end
    end
    local ERROR_MSG = "HEAD: Unable to find current HEAD"
    local current_head, status_code = require("ever._core.run_cmd").run_cmd("git rev-parse --abbrev-ref HEAD")
    if status_code ~= 0 then
        return ERROR_MSG
    end
    -- If current head is HEAD and not a branch, we're in a detached head
    if current_head == "HEAD" then
        local current_head_hash, hash_status_code = require("ever._core.run_cmd").run_cmd("git rev-parse --short HEAD")
        if hash_status_code ~= 0 then
            return ERROR_MSG
        end
        return string.format("HEAD: %s (detached head)", current_head_hash[1])
    end
    return "HEAD: " .. current_head[1]
end

---@param bufnr integer
---@param line string
---@param line_num integer
function M.highlight_head_line(bufnr, line, line_num)
    if line:match("^HEAD:") or line:match("^Branch:") then
        local head_start, head_end = line:find("%s%S+")
        require("ever._ui.highlight").highlight_line(bufnr, "Identifier", line_num, head_start, head_end)
    end
end

return M
