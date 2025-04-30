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
    return cmd
end

--- Expand `%` to current file
---@param input_args vim.api.keyset.create_user_command.command_args
---@return string
M.parse = function(input_args)
    local parsed_cmd = replace_percent_outside_quotes(input_args.args)

    local is_visual_command = input_args.range == 2
    if is_visual_command then
        parsed_cmd = parse_visual_command(parsed_cmd, input_args)
    end
    return parsed_cmd
end

return M
