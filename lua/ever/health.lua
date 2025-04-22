--- Make sure `ever` will work as expected.
--- At minimum, we validate that the user's configuration is correct. But other
--- checks can happen here if needed.
---@module 'ever.health'

local configuration_ = require("ever._core.configuration")
local vlog = require("ever._vendors.vlog").new()

local M = {}

-- NOTE: This file is defer-loaded so it's okay to run this in the global scope
configuration_.initialize_data_if_needed()

function M.check()
    if vlog and vlog.debug then
        vlog.debug("Running ever health check.")
    end
    vim.health.start("Configuration")
end

return M
