local M = {}

local cmd_ui_map = {
    difftool = function(cmd)
        require("ever._ui.interceptors.difftool").render(cmd)
    end,
    staging_area = function(cmd)
        require("ever._ui.interceptors.staging_area").render(cmd)
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
    if cmd:match("^difftool%s*$") then
        return cmd_ui_map.staging_area
    end
    return cmd_ui_map[subcommand]
end

return M
