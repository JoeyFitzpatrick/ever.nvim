--- All `ever` command definitions.

local cli_subcommand = require("ever._cli.cli_subcommand")

local _PREFIX = "E"

---@type ever.ParserCreator
local _SUBCOMMANDS = function()
    local cmdparse = require("ever._cli.cmdparse")
    local status = require("ever._commands.status.parser")

    local root_parser = cmdparse.ParameterParser.new({ help = "The root of all commands." })
    local root_subparsers = root_parser:add_subparsers({ "command", help = "All root commands." })

    local parser = root_subparsers:add_parser({ name = _PREFIX, help = "The starting command." })
    local subparsers = parser:add_subparsers({ "commands", help = "All runnable commands." })

    subparsers:add_parser(status.make_parser())

    return root_parser
end

vim.api.nvim_create_user_command(_PREFIX, cli_subcommand.make_parser_triager(_SUBCOMMANDS), {
    nargs = "*",
    desc = "Ever's command API. Mostly the same as the Git API.",
    complete = cli_subcommand.make_parser_completer(_SUBCOMMANDS),
})

vim.keymap.set("n", "<Plug>(EverSayHi)", function()
    local configuration = require("ever._core.configuration")
    local ever = require("plugin.ever")

    configuration.initialize_data_if_needed()

    ever.run_hello_world_say_word("Hi!")
end, { desc = "Say hi to the user." })
