local get_commits_to_diff = require("ever._ui.interceptors.difftool")._get_commits_to_diff

describe("get commits to diff", function()
    it("should return an empty string if there are no commits to diff", function()
        assert.are.equal("", get_commits_to_diff("difftool"))
    end)
    it("should diff against HEAD when only one commit is passed in", function()
        assert.are.equal("abc123..HEAD", get_commits_to_diff("difftool -d --prompt abc123"))
    end)
    it("should return a commit range if there is one", function()
        assert.are.equal("abc123..def456", get_commits_to_diff("difftool abc123..def456"))
    end)
    it("should work if flags are passed in", function()
        assert.are.equal("abc123..def456", get_commits_to_diff("difftool -d --prompt abc123..def456"))
    end)
end)
