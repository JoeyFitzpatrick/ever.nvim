local M = {}

local cmd_ui_map = {
    difftool = function()
        require("ever._ui.interceptors.difftool").render()
    end,
}

---@param cmd string
---@return function | nil
function M.get_ui(cmd)
    local subcommand = cmd:match("%S+")
    if not subcommand then
        return function()
            require("ever._ui.home").open()
        end
    end
    return cmd_ui_map[subcommand]
end

return M
