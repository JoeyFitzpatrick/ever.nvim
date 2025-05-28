local M = {}

---@type table<string, fun(cmd?: string)>
local cmd_ui_map = {
    Hdiff = function(cmd)
        require("ever._ui.interceptors.split_diff").split_diff(cmd, "below")
    end,
    Vdiff = function(args)
        require("ever._ui.interceptors.split_diff").split_diff(args, "right")
    end,
    blame = function(cmd)
        require("ever._ui.interceptors.blame").render(cmd)
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
        require("ever._ui.interceptors.standard_interceptor").render(cmd)
    end
end

local BRANCH_UI_OPTIONS = {
    "branch",
    "--color",
    "--no-color",
    "-i",
    "--ignore-case",
    "--omit-empty",
    "--no-column",
    "-r",
    "--remotes",
    "-a",
    "--all",
    "-l",
    "--list",
    "--contains",
    "--no-contains",
    "--merged",
    "--no-merged",
    "--sort",
    "--points-at",
}

--- Some branch commands, like `git branch new-branch old-branch`,
--- should not open the special branch UI, and just run in terminal mode.
---@param cmd string
---@return function | nil
local function branch_interceptor(cmd)
    local has_only_ui_options = require("ever._core.texter").only_has_options(cmd, BRANCH_UI_OPTIONS)
    if has_only_ui_options then
        return function(branch_cmd)
            local bufnr = require("ever._ui.elements").new_buffer({ buffer_name = "EverBranch-" .. os.tmpname() })
            require("ever._ui.home_options.branch").render(bufnr, { start_line = 0, cmd = branch_cmd })
        end
    end
    return nil
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
    if vim.startswith(cmd, "branch") then
        -- If this is nil, fall back to terminal mode
        return branch_interceptor(cmd)
    end
    local is_help_command = cmd:match("%-h%s*$") or cmd:match("%-%-help%s*$")
    if is_help_command then
        return cmd_ui_map.help
    end
    return cmd_ui_map[subcommand]
end

return M
