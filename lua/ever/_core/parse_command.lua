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

--- Expand `%` to current file
---@param cmd string
---@return string
M.parse = function(cmd)
    local parsed_cmd = replace_percent_outside_quotes(cmd)
    return parsed_cmd
end

return M
