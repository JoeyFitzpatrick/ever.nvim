--- All `ever` command definitions.

local PREFIX = "G"

---@param bufnr integer
---@param strategy { display_strategy: string, insert: boolean }
local function open_terminal_buffer(bufnr, strategy)
    local strategies = require("lua.ever._constants.command_strategies").STRATEGIES
    if vim.tbl_contains({ "above", "below", "right", "left" }, strategy.display_strategy) then
        vim.api.nvim_open_win(bufnr, true, { split = "below" })
    elseif strategy.display_strategy == strategies.FULL then
        vim.api.nvim_win_set_buf(0, bufnr)
    elseif strategy.display_strategy == strategies.DYNAMIC then
        print("Dynamic not implemented yet")
    end
end

---@param input_args vim.api.keyset.create_user_command.command_args
local function run_command(input_args)
    local bufnr = vim.api.nvim_create_buf(false, true)
    local base_cmd = input_args.args:match("(%S+)%s?")
    local strategy = require("lua.ever._constants.command_strategies")[base_cmd]
        or require("lua.ever._constants.command_strategies").default
    open_terminal_buffer(bufnr, strategy)
    local git_command = "git " .. input_args.args
    vim.fn.jobstart(git_command, { term = true })
end

vim.api.nvim_create_user_command(PREFIX, run_command, {
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
