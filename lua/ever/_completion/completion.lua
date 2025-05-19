local M = {}

---@param subcommand string
---@return table<string, string> | nil
local function subcommand_options(subcommand)
    local subcommand_tbl = require("ever._constants.command_options")[subcommand]
    if not subcommand_tbl then
        return nil
    end
    return subcommand_tbl.options
end

---@param cmdline string
---@return string | nil
local function get_subcommand(cmdline)
    local words = {}
    for word in cmdline:gmatch("%S+") do
        table.insert(words, word)
    end
    return words[2]
end

local all_branches_command = "git for-each-ref --format='%(refname:short)' refs/heads/ refs/remotes/"
local SUBCOMMAND_TO_ARGUMENTS_MAP = {
    Vdiff = all_branches_command,
    Hdiff = all_branches_command,
    checkout = all_branches_command,
    switch = all_branches_command,
    merge = all_branches_command,
    rebase = all_branches_command,
    revert = all_branches_command,
}

---@param subcommand string
---@return string[] | nil
local function get_arguments(subcommand)
    local cmd = SUBCOMMAND_TO_ARGUMENTS_MAP[subcommand]
    if not cmd then
        return nil
    end
    local output = vim.fn.systemlist(cmd)
    if vim.v.shell_error ~= 0 then
        return nil
    end
    return output
end

--- takes an arbitrary git command, and returns completion options
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
        local subcommand = get_subcommand(cmdline)
        if not subcommand then
            return { arglead, cmdline }
        end
        if arglead:sub(1, 1) == "-" then
            return subcommand_options(subcommand) or {}
        end
        local completion_arguments = get_arguments(subcommand)
        if completion_arguments ~= nil then
            return completion_arguments
        end
        local completion_options = subcommand_options(subcommand)
        if completion_options ~= nil then
            return completion_options
        end
    end
    return {}
end

return M
