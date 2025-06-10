local commit_hash_to_hex = require("trunks._ui.highlight").commit_hash_to_hex

describe("commit_hash_to_hex", function()
    it("should generate a hex from a commit hash", function()
        local expected = {
            hex = "#ABC123",
            stripped_hash = "abc123",
        }
        assert.are.same(expected, commit_hash_to_hex("abc123", 1))
    end)

    it("should generate a hex from an initial commit", function()
        local expected = {
            hex = "#ABC123",
            stripped_hash = "abc123",
        }
        assert.are.same(expected, commit_hash_to_hex("^abc123", 1))
    end)

    it("should generate a hex from a commit with all numbers", function()
        local expected = {
            hex = "#123456",
            stripped_hash = "123456",
        }
        assert.are.same(expected, commit_hash_to_hex("123456", 1))
    end)

    it("should generate a hex from a commit with all letters", function()
        local expected = {
            hex = "#ABCDEF",
            stripped_hash = "abcdef",
        }
        assert.are.same(expected, commit_hash_to_hex("abcdef", 1))
    end)

    it("should generate a hex from a commit with all zeroes", function()
        local expected = {
            hex = "#000000",
            stripped_hash = "000000",
        }
        assert.are.same(expected, commit_hash_to_hex("000000", 1))
    end)
end)
