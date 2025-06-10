--- Make manipulating Lua text easier.
---
---@module 'trunks._core.texter'
---

local M = {}

--- Check if `character` is "regular" text but not alphanumeric.
---
--- Examples would be Asian characters, Arabic, emojis, etc.
---
---@param character string Some single-value to check.
---@return boolean # If found return `true`.
---
function M.is_unicode(character)
    local code_point = character:byte()
    return code_point > 127
end

--- Surround `text` with quotes
---@param text string The text to surround with quotes
---@return string # The text surrounded with quotes
function M.surround_with_quotes(text)
    return "'" .. text .. "'"
end

--- This is used to find an argument in a command
--- That does not begin with dashes.
--- For git log, this determines whether we are
--- viewing commits for HEAD or for a specific branch.
function M.find_non_dash_arg(input)
    local args = vim.split(input, " ", { plain = true, trimempty = true })
    for _, arg in ipairs(args) do
        -- If arg == "--", then the next arg will have been preceded by
        -- "-- ", e.g. "git log -- somepath/somefile.txt", because
        -- we are splitting on " ".
        -- We don't want to match that.
        if arg == "--" then
            return nil
        end
        if not arg:match("^%-+%s-") then
            return arg
        end
    end
    return nil
end

--- Check whether a given command contains any of a list of options.
--- Some commands are handled differently depending on the options given.
---@param cmd string
---@param options string[]
---@return boolean
function M.has_options(cmd, options)
    local parsed_options = {}
    for word in cmd:gmatch("%-%-%S+") do
        table.insert(parsed_options, word)
    end
    for word in cmd:gmatch("%-%a") do
        table.insert(parsed_options, word)
    end
    for _, opt in ipairs(parsed_options) do
        if vim.tbl_contains(options, opt) then
            return true
        end
    end
    return false
end

--- Check if a given string only contains any of a list of options.
--- Some commands are handled differently depending on the options given.
---@param cmd string
---@param options string[]
---@return boolean
function M.only_has_options(cmd, options)
    for word in cmd:gmatch("%S+") do
        if not vim.tbl_contains(options, word) then
            return false
        end
    end
    return true
end

return M
