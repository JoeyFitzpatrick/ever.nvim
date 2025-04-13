--- Make sure `ever` will work as expected.
---
--- At minimum, we validate that the user's configuration is correct. But other
--- checks can happen here if needed.
---
---@module 'ever.health'
---

local configuration_ = require("ever._core.configuration")
local tabler = require("ever._core.tabler")
local vlog = require("ever._vendors.vlog")

local M = {}

-- NOTE: This file is defer-loaded so it's okay to run this in the global scope
configuration_.initialize_data_if_needed()

--- Add issues to `array` if there are errors.
---
--- Todo:
---     Once Neovim 0.10 is dropped, use the new function signature
---     for vim.validate to make this function cleaner.
---
---@param array string[]
---    All of the cumulated errors, if any.
---@param name string
---    The key to check for.
---@param value_creator fun(): any
---    A function that generates the value.
---@param expected string | fun(value: any): boolean
---    If `value_creator()` does not match `expected`, this error message is
---    shown to the user.
---@param message (string | boolean)?
---    If it's a string, it's the error message when
---    `value_creator()` does not match `expected`. When it's
---    `true`, it means it's okay for `value_creator()` not to match `expected`.
---
local function _append_validated(array, name, value_creator, expected, message)
    local success, value = pcall(value_creator)

    if not success then
        table.insert(array, value)

        return
    end

    local validated
    success, validated = pcall(vim.validate, {
        -- TODO: I think the Neovim type annotation is wrong. Once Neovim
        -- 0.10 is dropped let's just change this over to the new
        -- vim.validate signature.
        --
        ---@diagnostic disable-next-line: assign-type-mismatch
        [name] = { value, expected, message },
    })

    if not success then
        table.insert(array, validated)
    end
end

--- Check all "cmdparse" values for issues.
---
---@param data ever.Configuration All of the user's fallback settings.
---@return string[] # All found issues, if any.
---
local function _get_cmdparse_issues(data)
    local output = {}

    _append_validated(output, "cmdparse.auto_complete.display.help_flag", function()
        return tabler.get_value(data, { "cmdparse", "auto_complete", "display", "help_flag" })
    end, "boolean", true)

    return output
end

--- Check all "commands" values for issues.
---
---@param data ever.Configuration All of the user's fallback settings.
---@return string[] # All found issues, if any.
---
local function _get_command_issues(data)
    local output = {}

    _append_validated(output, "commands.goodnight_moon.read.phrase", function()
        return tabler.get_value(data, { "commands", "goodnight_moon", "read", "phrase" })
    end, "string")

    _append_validated(output, "commands.hello_world.say.repeat", function()
        return tabler.get_value(data, { "commands", "hello_world", "say", "repeat" })
    end, function(value)
        return type(value) == "number" and value > 0
    end, "a number (value must be 1-or-more)")

    return output
end

--- Check `data` for problems and return each of them.
---
---@param data ever.Configuration? All extra customizations for this plugin.
---@return string[] # All found issues, if any.
---
function M.get_issues(data)
    if not data or vim.tbl_isempty(data) then
        data = configuration_.resolve_data(vim.g.ever_configuration)
    end

    local output = {}
    vim.list_extend(output, _get_cmdparse_issues(data))
    vim.list_extend(output, _get_command_issues(data))

    return output
end

--- Make sure `data` will work for `ever`.
---
---@param data ever.Configuration? All extra customizations for this plugin.
---
function M.check(data)
    vlog.debug("Running ever health check.")

    vim.health.start("Configuration")

    local issues = M.get_issues(data)

    if vim.tbl_isempty(issues) then
        vim.health.ok("Your vim.g.ever_configuration variable is great!")
    end

    for _, issue in ipairs(issues) do
        vim.health.error(issue)
    end
end

return M
