--- All functions and data to help customize `trunks` for this user.
---@module 'trunks._core.configuration'

local M = {}

-- NOTE: Don't remove this line. It makes the Lua module much easier to reload
vim.g.loaded_trunks = false

M.DATA = {}

---@type trunks.Configuration
local _DEFAULTS = require("trunks._core.default_configuration")

function M.initialize_data()
    M.DATA = vim.tbl_deep_extend("force", _DEFAULTS, vim.g.trunks_configuration or {})
    vim.fn.system("git -C . rev-parse 2>/dev/null")
    vim.g.trunks_in_git_repo = vim.v.shell_error == 0
end

return M
