--- Make sure `trunks` will work as expected.
--- At minimum, we validate that the user's configuration is correct. But other
--- checks can happen here if needed.
---@module 'trunks.health'

---@param exectuable string
---@param warn_only? boolean
local function check_executable(exectuable, warn_only)
    if vim.fn.executable(exectuable) == 1 then
        vim.health.ok(exectuable .. " is installed")
        return
    end
    if warn_only then
        vim.health.warn(exectuable .. " is not installed")
    else
        vim.health.error(exectuable .. " is not installed")
    end
end

---@param input table
---@param defaults table
---@param path? string
---@return { message: string, advice: string }[]
local function validate_config(input, defaults, path)
    path = path or ""
    local errors = {}

    for k, v in pairs(input) do
        local current_path = path == "" and k or path .. "." .. k

        if type(v) == "table" then
            if defaults[k] == nil then
                local config_error = {}
                config_error.message = current_path .. " is not a valid configuration section"

                local valid_values = {}
                for key, _ in pairs(defaults) do
                    table.insert(valid_values, key)
                end
                config_error.advice = "Valid values:\n\t" .. table.concat(valid_values, "\n\t")
                table.insert(errors, config_error)
            else
                local sub_errors = validate_config(v, defaults[k], current_path)
                for _, err in ipairs(sub_errors) do
                    table.insert(errors, err)
                end
            end
        else
            if defaults[k] == nil and v ~= nil then
                local valid_values = {}
                for key, _ in pairs(defaults) do
                    table.insert(valid_values, key)
                end
                local advice = "Valid values:\n\t" .. table.concat(valid_values, "\n\t")
                table.insert(
                    errors,
                    { message = current_path .. " is not a valid configuration value", advice = advice }
                )
            end
        end
    end

    return errors
end

local configuration = require("trunks._core.configuration")
local vlog = require("trunks._vendors.vlog").new()

local M = {}

-- NOTE: This file is defer-loaded so it's okay to run this in the global scope
configuration.initialize_data()

function M.check()
    if vlog and vlog.debug then
        vlog.debug("Running ever health check.")
    end
    vim.health.start("Configuration")
    local errors = validate_config(configuration.DATA, require("trunks._core.default_configuration"))
    if #errors == 0 then
        vim.health.ok("Configuration is valid")
    else
        for _, config_error in ipairs(errors) do
            vim.health.warn(config_error.message)
            vim.health.info(config_error.advice)
        end
    end

    vim.health.start("Executables")
    check_executable("git")
    vim.fn.system("git -C . rev-parse 2>/dev/null")
    local in_git_repo = vim.v.shell_error == 0
    if in_git_repo then
        vim.health.ok("Currently in git repository")
    else
        vim.health.error("Not currently in git repository")
    end
end

return M
