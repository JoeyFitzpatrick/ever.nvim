local constants = require("ever._core.nested-buffers.constants")

local M = {}

M.setup_nested_buffers = function()
    local in_terminal_buffer = (os.getenv(constants.ever_pipe_path_host_env_var) ~= nil)

    if in_terminal_buffer then
        require("ever._core.nested-buffers.client")
    else
        require("ever._core.nested-buffers.server")
    end
end

return M
