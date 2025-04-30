--- All functions and data to help customize `ever` for this user.
---@module 'ever._core.configuration'

local M = {}

-- NOTE: Don't remove this line. It makes the Lua module much easier to reload
vim.g.loaded_ever = false

M.DATA = {}

---@type ever.Configuration
local _DEFAULTS = require("ever._core.default_configuration")

function M.initialize_data()
    M.DATA = vim.tbl_deep_extend("force", _DEFAULTS, vim.g.ever_configuration or {})
    vim.fn.system("git -C . rev-parse 2>/dev/null")
    vim.g.ever_in_git_repo = vim.v.shell_error == 0
end

return M
