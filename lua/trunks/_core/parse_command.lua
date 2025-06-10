local M = {}

---@param input string
---@return string
local function replace_percent_outside_quotes(input)
    local in_quotes = false
    local quote_char = nil

    local parsed_cmd = input:gsub(".", function(c)
        if not in_quotes then
            if c == '"' or c == "'" then
                in_quotes = true
                quote_char = c
                return c
            elseif c == "%" then
                return vim.api.nvim_buf_get_name(0)
            else
                return c
            end
        else
            if c == quote_char then
                in_quotes = false
                quote_char = nil
            end
            return c
        end
    end)
    return parsed_cmd
end

---@param cmd string
---@param input_args vim.api.keyset.create_user_command.command_args
---@return string
local function parse_visual_command(cmd, input_args)
    if cmd:match("^log %-L") then
        return "log -L " .. input_args.line1 .. "," .. input_args.line2 .. ":" .. vim.api.nvim_buf_get_name(0)
    end

    if cmd:match("^log %-S") then
        return string.format("log -S '%s' -w", require("trunks._ui.utils.ui_utils").get_visual_selection())
    end
    return cmd
end

---@type table<string, fun(cmd: string): string>
local subcommand_parsers = {
    switch = function(cmd)
        if cmd:match("switch%s%S+$") then
            local parsed_cmd, _ = cmd:gsub("origin/", "", 1)
            return parsed_cmd
        end
        return cmd
    end,
}

--- Parsing rules for subcommands. For instance, if `:G switch origin/some-branch`
--- is invoked with no options, remove 'origin/' from the branch to switch to.
---
--- If there is no parser for the given subcommand, just return the command.
---@param cmd string
---@return string
local function parse_subcommand(cmd)
    local subcommand = cmd:match("^%S+")
    if not subcommand then
        return cmd
    end
    local parser = subcommand_parsers[subcommand]
    if not parser then
        return cmd
    end
    return parser(cmd)
end

--- Expand `%` to current file.
--- Also modify command in some special cases.
---@param input_args vim.api.keyset.create_user_command.command_args
---@return string
M.parse = function(input_args)
    local parsed_cmd = replace_percent_outside_quotes(input_args.args)
    parsed_cmd = parse_subcommand(parsed_cmd)

    local is_visual_command = input_args.range == 2
    if is_visual_command then
        parsed_cmd = parse_visual_command(parsed_cmd, input_args)
    end
    return parsed_cmd
end

return M
