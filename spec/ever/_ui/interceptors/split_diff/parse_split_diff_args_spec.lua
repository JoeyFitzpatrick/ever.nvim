local parse_split_diff_args = require("ever._ui.interceptors.split_diff")._parse_split_diff_args

describe("parse_split_diff_args", function()
    before_each(function()
        vim.fn.expand = function()
            return "%"
        end
    end)

    it("should parse args when no commit is given", function()
        local expected = { filepath = "%", commit = "HEAD" }
        assert.are.same(expected, parse_split_diff_args("Vdiff"))
        -- The input string should never be empty, but testing anyways
        assert.are.same(expected, parse_split_diff_args(""))
    end)

    it("should parse args when a commit is given", function()
        local commit = "abc123"
        local expected = { filepath = "%", commit = commit }
        assert.are.same(expected, parse_split_diff_args("Vdiff " .. commit))
    end)

    it("should parse args when a branch is given", function()
        local branch = "me/some-branch-here"
        local expected = { filepath = "%", commit = branch }
        assert.are.same(expected, parse_split_diff_args("Vdiff " .. branch))
    end)

    it("should only use first arg when multiple are given", function()
        local branch = "me/some-branch-here"
        local bad_input = branch .. " random -- text"
        local expected = { filepath = "%", commit = branch }
        assert.are.same(expected, parse_split_diff_args("Vdiff " .. bad_input))
    end)
end)
