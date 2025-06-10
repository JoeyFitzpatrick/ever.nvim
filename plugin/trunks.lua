--- All `trunks` command definitions.

local PREFIX = "G"

---@param input_args vim.api.keyset.create_user_command.command_args
local function run_command(input_args)
    local cmd = require("trunks._core.parse_command").parse(input_args)
    local cmd_with_git_prefix = "git " .. cmd
    if input_args.bang then
        require("trunks._ui.elements").terminal(cmd_with_git_prefix, { display_strategy = "full", insert = true })
        return
    end
    local ui_function = require("trunks._ui.interceptors").get_ui(cmd)
    if ui_function then
        ui_function(cmd)
    else
        require("trunks._ui.elements").terminal(cmd_with_git_prefix)
    end
end

vim.api.nvim_create_user_command(PREFIX, function(input_args)
    require("trunks")
    if vim.g.trunks_in_git_repo == false then
        if input_args.args and input_args.args:match("^init") then
            run_command(input_args)
            vim.g.trunks_in_git_repo = true
            return
        else
            vim.notify("trunks: working directory does not belong to a Git repository", vim.log.levels.ERROR)
            return
        end
    end
    run_command(input_args)
end, {
    nargs = "*",
    desc = "Trunks's command API. Mostly the same as the Git API.",
    bang = true, -- with a bang, always run command in terminal mode (no ui)
    range = true, -- some commands, like ":G log -L", work on a range of lines
    complete = function(arglead, cmdline)
        local completion = require("trunks._completion").complete_git_command(arglead, cmdline)
        return vim.tbl_filter(function(val)
            return vim.startswith(val, arglead)
        end, completion)
    end,
})

require("trunks._core.nested-buffers").prevent_nested_buffers()
