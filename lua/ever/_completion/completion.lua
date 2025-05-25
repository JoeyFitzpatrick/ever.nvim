local M = {}

---@param cmdline string
---@return string | nil
local function get_subcommand(cmdline)
    local words = {}
    for word in cmdline:gmatch("%S+") do
        table.insert(words, word)
    end
    return words[2]
end

local function branch_completion()
    local all_branches_command = "git for-each-ref --format='%(refname:short)' refs/heads/ refs/remotes/"
    local branches = vim.fn.systemlist(all_branches_command)
    if vim.v.shell_error ~= 0 then
        return {}
    end
    return branches
end

--- Takes a git command in command mode, and returns completion options.
---@param arglead string
---@param cmdline string
---@return string[]
M.complete_git_command = function(arglead, cmdline)
    local space_count = 0
    for _ in string.gmatch(cmdline, " ") do
        space_count = space_count + 1
    end
    if space_count == 1 then
        return require("ever._constants.porcelain_commands")
    end
    if space_count > 1 then
        -- Check that we have a valid git subcommand
        local subcommand = get_subcommand(cmdline)
        if not subcommand then
            return {}
        end
        -- Check that we have completion for this subcommand
        local completion_tbl = require("ever._constants.command_options")[subcommand]
        if not completion_tbl then
            return {}
        end

        -- If a "-" is typed, provide option completion, e.g. "--no-verify"
        if arglead:sub(1, 1) == "-" then
            return completion_tbl.options or {}
        end

        if completion_tbl.completion_type == "branch" then
            return branch_completion()
        end

        if completion_tbl.completion_type == "subcommand" then
            return completion_tbl.subcommands or {}
        end
        return completion_tbl.options or {}
    end
    return {}
end

return M
