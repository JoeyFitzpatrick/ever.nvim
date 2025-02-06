---@class ever.RunCmdOpts
---@field stdin? string[]
---@field rerender? boolean

local M = {}

--- Runs a command and returns the output.
---@param cmd string -- Command to run
---@param opts? ever.RunCmdOpts -- options, such as special error handling
---@return string[] -- command output
M.run_cmd = function(cmd, opts)
    opts = opts or {}
    local output
    if opts.stdin then
        output = vim.fn.systemlist(cmd, opts.stdin)
    else
        output = vim.fn.systemlist(cmd)
    end
    if opts.rerender then
        require("ever._core.register").rerender_buffers()
    end
    return output
end

--- Runs a command that doesn't display output.
--- This is used in cases where the UI handles visual updates.
--- This function prints an error message if one is generated by the command.
---@param cmd string -- Command to run
---@param opts? ever.RunCmdOpts -- options, such as special error handling
---@return "success" | "error"
M.run_hidden_cmd = function(cmd, opts)
    opts = opts or {}
    local output
    if opts.stdin then
        output = vim.fn.system(cmd, opts.stdin)
    else
        output = vim.fn.system(cmd)
    end
    if vim.v.shell_error ~= 0 then
        vim.notify(output.stderr, vim.log.levels.ERROR)
        return "error"
    end
    return "success"
end

return M
