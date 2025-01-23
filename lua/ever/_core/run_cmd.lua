---@class ever.RunCmdOpts

local M = {}

--- Runs a command and returns the output.
---@param cmd string[] -- Command to run
---@param opts? ever.RunCmdOpts -- options, such as special error handling
---@return string[] -- command output
M.run_cmd = function(cmd, opts)
    local output = vim.system(cmd, { text = true }):wait()
    if output.stdout and output.stdout ~= "" then
        return vim.split(output.stdout, "\n")
    else
        return vim.split(output.stderr, "\n")
    end
end

return M
