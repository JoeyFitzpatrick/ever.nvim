local M = {}

local cmd_ui_map = {
    blame = function(cmd)
        require("ever._ui.interceptors.blame").render(cmd)
    end,
    branch = function(cmd)
        local bufnr = require("ever._ui.elements").new_buffer({ buffer_name = "EverBranch-" .. os.tmpname() })
        require("ever._ui.home_options.branch").render(bufnr, { start_line = 0, cmd = cmd })
    end,
    difftool = function(cmd)
        require("ever._ui.interceptors.difftool").render(cmd)
    end,
    help = function(cmd)
        -- col -b is needed to remove bad characters from --help output
        require("ever._ui.interceptors.standard_interceptor").render(cmd .. " | col -b")
        -- Setting the filetype to man add nice highlighting.
        -- It also makes the "q" keymap exit neovim if this is the last buffer, so we need to set it again
        vim.bo["filetype"] = "man"
        vim.keymap.set("n", "q", function()
            require("ever._core.register").deregister_buffer(0, { skip_go_to_last_buffer = true })
        end, { buffer = 0 })
    end,
    log = function(cmd)
        local bufnr = require("ever._ui.elements").new_buffer({ buffer_name = "EverLog-" .. os.tmpname() })
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
        require("ever._ui.interceptors.standard_interceptor").render(cmd .. " | col -b")
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
    local is_help_command = cmd:match("%-h%s*$") or cmd:match("%-%-help%s*$")
    if is_help_command then
        return cmd_ui_map.help
    end
    return cmd_ui_map[subcommand]
end

return M
