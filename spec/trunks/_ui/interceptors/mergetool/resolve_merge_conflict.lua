local resolve_merge_conflict = require("trunks._ui.interceptors.mergetool.handle_merge_conflict").resolve_merge_conflict

local MERGE_CONFLICT_LINES = {
    "<<<<<<< HEAD",
    "Content for branch1",
    "||||||| 055d17b",
    "Initial content",
    "=======",
    "Content for branch2",
    ">>>>>>> branch2",
}

describe("resolve merge conflict", function()
    it("should return lines that accept the base in a merge conflict", function()
        local expected = {
            "Initial content",
        }
        assert.are.same(expected, resolve_merge_conflict(MERGE_CONFLICT_LINES, "base"))
    end)
    it("should return lines that accept 'ours' in a merge conflict", function()
        local expected = {
            "Content for branch1",
        }
        assert.are.same(expected, resolve_merge_conflict(MERGE_CONFLICT_LINES, "ours"))
    end)
    it("should return lines that accept 'theirs' in a merge conflict", function()
        local expected = {
            "Content for branch2",
        }
        assert.are.same(expected, resolve_merge_conflict(MERGE_CONFLICT_LINES, "theirs"))
    end)
    it("should return lines that accept all changes in a merge conflict", function()
        local expected = {
            "Content for branch1",
            "Initial content",
            "Content for branch2",
        }
        assert.are.same(expected, resolve_merge_conflict(MERGE_CONFLICT_LINES, "all"))
    end)
end)
