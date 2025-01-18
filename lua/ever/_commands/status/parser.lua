--- The main parser for the `:Ever status` command.
---
---@module 'ever._commands.status.parser'
---

local cmdparse = require("ever._cli.cmdparse")

local M = {}

---@return cmdparse.ParameterParser # The main parser for the `:Ever status` command.
function M.make_parser()
    local parser = cmdparse.ParameterParser.new({ "status", help = "Prepare to sleep or sleep." })

    parser:add_parameter({ "--long", action = "store_true", help = "Standard status output" })
    parser:add_parameter({ "--short", action = "store_true", help = "Short status output" })
    -- parser:add_parameter({ "-v", action = "store_true", count = "*", destination = "verbose", help = "The -v flag." })

    parser:set_execute(function(data)
        ---@cast data ever.NamespaceExecuteArguments
        local runner = require("ever._commands.status.runner")

        local names = {}

        for _, argument in ipairs(data.input.arguments) do
            table.insert(names, argument.name)
        end

        runner.run(names)
    end)

    return parser
end

return M
