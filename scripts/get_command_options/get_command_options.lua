-- This script generates the completion options.
-- It can be run via the terminal by running this:
-- nvim --headless -c 'luafile scripts/get_command_options/get_command_options.lua' -c 'qa'
-- Or just source the file by running `:h source` with this file open in neovim

---@alias ever.CommandCompletionType "branch" | "filepath" | "subcommand"

---@class ever.CompletionParams
---@field completion_type? ever.CommandCompletionType
---@field options string[]
---@field subcommands? string[]

local M = {}

local COMMANDS_WITH_BRANCH_COMPLETION = {
    "Vdiff",
    "Hdiff",
    "archive",
    "checkout",
    "merge",
    "rebase",
    "revert",
    "switch",
}

local COMMANDS_WITH_FILEPATH_COMPLETION = {
    "add",
    "diff",
    "grep",
    "mv",
    "restore",
    "rm",
}

local parsed_commands = {}
local cmd_option_pattern = "%-%-[a-zA-Z0-9][a-zA-Z0-9][a-zA-Z0-9%-]*"
local get_subcommand_pattern = function(cmd)
    return "git " .. cmd .. " %[?([%w%-]+)"
end

---@param help_text string
---@param cmd string
---@return ever.CompletionParams
M._parse_options_from_help_text = function(help_text, cmd)
    local completion_type = nil
    ---@type ever.CompletionParams
    local completion_params = { options = {} }
    for flag in help_text:gmatch(cmd_option_pattern) do
        completion_params.options[flag] = flag
    end
    for subcommand in help_text:gmatch(get_subcommand_pattern(cmd)) do
        if subcommand:match("^[^%-]") then
            completion_type = "subcommand"
        end
        if completion_params.subcommands == nil then
            completion_params.subcommands = {}
        end
        completion_params.subcommands[subcommand] = subcommand
    end
    if vim.tbl_contains(COMMANDS_WITH_BRANCH_COMPLETION, cmd) then
        completion_type = "branch"
    end
    if vim.tbl_contains(COMMANDS_WITH_FILEPATH_COMPLETION, cmd) then
        completion_type = "filepath"
    end
    return {
        options = completion_params.options,
        subcommands = completion_params.subcommands,
        completion_type = completion_type,
    }
end

---@param cmds string[] | nil
M.get_command_options = function(cmds)
    local cmd_types = {
        "list-mainporcelain",
        "list-ancillarymanipulators",
        "list-ancillaryinterrogators",
        "list-foreignscminterface",
        "list-plumbingmanipulators",
        "list-plumbinginterrogators",
        "others",
        "alias",
    }
    cmds = cmds or vim.fn.systemlist("git --list-cmds=" .. table.concat(cmd_types, ","))
    for _, cmd in ipairs(cmds) do
        local help_text
        if cmd == "log" then
            local log_help = require("scripts.get_command_options.log_help").log_help
            help_text = log_help
        else
            local help_text_obj = vim.system({ "git", cmd, "-h" }):wait()
            help_text = help_text_obj.stdout
            if not help_text or help_text:len() == 0 then
                help_text = help_text_obj.stderr
            end
            if not help_text then
                error("Could not get help text for command: " .. cmd)
            end
        end
        local parsed_options = M._parse_options_from_help_text(help_text, cmd)
        parsed_commands[cmd] = parsed_options
    end

    local function write_table_to_file(tbl, filename)
        local file = io.open(filename, "w")
        if file then
            local table_string = vim.inspect(tbl)
            file:write("return " .. table_string)
            file:close()
        else
            error("Could not open file " .. filename .. " for writing.")
        end
    end

    local filepath = "lua/ever/_constants/command_options.lua"
    write_table_to_file(parsed_commands, filepath)
    os.execute("stylua " .. filepath)
    print("done")
end

M.get_command_options()

return M
