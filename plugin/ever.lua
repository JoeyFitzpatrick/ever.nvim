--- All `ever` command definitions.

local PREFIX = "G"

---@param input_args vim.api.keyset.create_user_command.command_args
local function run_command(input_args)
    local cmd = require("ever._core.parse_command").parse(input_args.args)
    local cmd_with_git_prefix = "git " .. cmd
    if input_args.bang then
        require("ever._ui.elements").terminal(cmd_with_git_prefix, { display_strategy = "full", insert = true })
        return
    end
    local ui_function = require("ever._ui.interceptors").get_ui(cmd)
    if ui_function then
        ui_function(cmd)
    else
        require("ever._ui.elements").terminal(cmd_with_git_prefix)
    end
end

vim.api.nvim_create_user_command(PREFIX, function(input_args)
    require("ever")
    if vim.g.ever_in_git_repo == false then
        vim.notify("ever: working directory does not belong to a Git repository", vim.log.levels.ERROR)
        return
    end
    run_command(input_args)
end, {
    nargs = "*",
    desc = "Ever's command API. Mostly the same as the Git API.",
    bang = true, -- with a bang, always run command in terminal mode (no ui)
    complete = function(arglead, cmdline)
        local completion = require("ever._completion").complete_git_command(arglead, cmdline)
        return vim.tbl_filter(function(val)
            return vim.startswith(val, arglead)
        end, completion)
    end,
    range = true,
})

require("ever._ui.popups.plug_mappings").setup_plug_mappings()
