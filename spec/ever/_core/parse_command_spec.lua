local parse = require("ever._core.parse_command").parse

describe("parse command", function()
    before_each(function()
        vim.api.nvim_buf_get_name = function()
            return "somefile.txt"
        end
    end)

    it("replaces `%` with the current file name", function()
        local expected = "git log somefile.txt"
        assert.are.equal(expected, parse({ args = "git log %" }))
    end)

    it("does not replace `%` if it is enclosed in quotes", function()
        local expected = "git grep 'text%'"
        assert.are.equal(expected, parse({ args = expected }))
    end)

    it("fills out a visual git log -L command", function()
        local expected = "log -L 40,50:somefile.txt"
        assert.are.equal(expected, parse({ range = 2, line1 = 40, line2 = 50, args = "log -L" }))
    end)

    it("returns original command for unsupported visual command", function()
        local expected = "status --porcelain -- somefile.txt"
        assert.are.equal(expected, parse({ range = 2, line1 = 40, line2 = 50, args = "status --porcelain -- %" }))
    end)
end)
