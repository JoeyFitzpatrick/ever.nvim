local get_line_without_num_commits = require("trunks._ui.utils.num_commits_pull_push")._get_line_without_num_commits

describe("get line without num commits", function()
    it("should return a branch that has num commit arrows", function()
        local line = "some-branch ↓↑"
        local expected = "some-branch"
        assert.are.equal(expected, get_line_without_num_commits(line))
    end)

    it("should return a branch without num commit arrows", function()
        local line = "some-branch"
        local expected = "some-branch"
        assert.are.equal(expected, get_line_without_num_commits(line))
    end)

    it("should return full text when in a rebase", function()
        local line = "(no branch, rebasing <branch-name>)"
        local expected = line
        assert.are.equal(expected, get_line_without_num_commits(line))
    end)
end)
