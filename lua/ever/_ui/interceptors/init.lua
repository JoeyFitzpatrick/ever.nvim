local M = {}

local cmd_ui_map = {
    blame = function(cmd)
        require("ever._ui.interceptors.blame").render(cmd)
    end,
    difftool = function(cmd)
        require("ever._ui.interceptors.difftool").render(cmd)
    end,
    log = function(cmd)
        local bufnr = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_win_set_buf(0, bufnr)
        require("ever._ui.home_options.log").render(bufnr, { start_line = 0, cmd = cmd })
    end,
    mergetool = function()
        require("ever._ui.interceptors.mergetool").render()
    end,
    reflog = function(cmd)
        require("ever._ui.interceptors.reflog").render(cmd)
    end,
    staging_area = function()
        local bufnr = require("ever._ui.interceptors.staging_area").render()
        require("ever._core.register").register_buffer(bufnr, {
            render_fn = function()
                require("ever._ui.home_options.status").set_lines(bufnr, {})
            end,
        })
    end,
}

local standard_output_commands = {
    "diff",
    "show",
}

for _, command in ipairs(standard_output_commands) do
    cmd_ui_map[command] = function(cmd)
        require("ever._ui.interceptors.standard_interceptor").render(cmd)
    end
end

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
