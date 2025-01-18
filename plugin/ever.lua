--- All `ever` command definitions.

local PREFIX = "G"

local function run_command(input_args)
    local git_command = "git " .. input_args.args
    local bufnr = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(bufnr, true, { split = "below" })
    vim.fn.jobstart(git_command, { term = true })
    vim.keymap.set("n", "p", function()
        local index = vim.api.nvim_win_get_cursor(win)[1]
        local line = vim.api.nvim_buf_get_lines(bufnr, index - 1, index, false)[1]
        vim.print(line)
    end, { buffer = bufnr })
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
