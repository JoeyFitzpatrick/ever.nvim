local only_has_options = require("ever._core.texter").only_has_options

describe("only_has_options", function()
    it("should return true when a command contains a given option", function()
        assert.are.equal(true, only_has_options("git branch --delete", { "git", "branch", "--delete" }))
    end)

    it("should return false when a command contains a non-given option", function()
        assert.are.equal(false, only_has_options("git branch --move", { "git", "branch", "--delete" }))
    end)

    it("should return true when a command contains some of the given options", function()
        assert.are.equal(true, only_has_options("git branch", { "git", "branch", "--delete" }))
    end)
end)
