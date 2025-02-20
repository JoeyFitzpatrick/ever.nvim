local parse = require("ever._core.parse_command").parse

describe("parse command", function()
    before_each(function()
        vim.api.nvim_buf_get_name = function()
            return "somefile.txt"
        end
    end)

    it("replaces `%` with the current file name", function()
        local expected = "git log somefile.txt"
        assert.are.equal(expected, parse("git log %"))
    end)

    it("does not replace `%` if it is enclosed in quotes", function()
        local expected = "git grep 'text%'"
        assert.are.equal(expected, parse(expected))
    end)
end)
