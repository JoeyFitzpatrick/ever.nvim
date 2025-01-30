--- All `ever` command definitions.

local PREFIX = "G"

---@param input_args vim.api.keyset.create_user_command.command_args
local function run_command(input_args)
    local args = input_args.args
    local ui_function = require("ever._ui.interceptors").get_ui(args)
    if ui_function then
        ui_function(args)
    else
        require("ever._ui.elements").terminal(input_args.args)
    end
end

vim.api.nvim_create_user_command(PREFIX, function(input_args)
    require("ever")
    run_command(input_args)
end, {
    nargs = "*",
    desc = "Ever's command API. Mostly the same as the Git API.",
    -- complete = cli_subcommand.make_parser_completer(_SUBCOMMANDS),
})

vim.keymap.set("n", "<Plug>(EverSayHi)", function()
    local configuration = require("ever._core.configuration")
    local ever = require("plugin.ever")

    configuration.initialize_data_if_needed()

    ever.run_hello_world_say_word("Hi!")
end, { desc = "Say hi to the user." })
