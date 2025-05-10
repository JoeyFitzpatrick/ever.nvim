-- This code was copied, then modified, from `nvim-unception`.
-- Copyright (c) 2022 Samuel Williams

local constants = require("ever._core.nested-buffers.constants")

local M = {}

M.prevent_nested_buffers = function()
    -- This is set in nested-buffers.server
    local in_terminal_buffer = (os.getenv(constants.ever_pipe_path_host_env_var) ~= nil)

    if in_terminal_buffer then
        require("ever._core.nested-buffers.client")
    end
end

M.setup_nested_buffers = function()
    if require("ever._core.configuration").DATA.prevent_nvim_inception then
        -- If this isn't set, nested-buffers.client will not run
        require("ever._core.nested-buffers.server")
    end
end

return M
