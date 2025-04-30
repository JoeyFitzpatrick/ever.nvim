local is_modified = require("ever._core.git").is_modified

describe("is_modified", function()
    it("returns true for valid modified statuses", function()
        local modified_statuses = {
            "AM",
            "AA",
            "RM",
            "MM",
            "AD",
        }
        for _, status in ipairs(modified_statuses) do
            assert.are.equal(true, is_modified(status))
        end
    end)

    it("returns false for non-partial statuses", function()
        local non_modified_statuses = {
            "M ",
            " M",
            "A ",
            "??",
            "R ",
            "D ",
            " D",
        }
        for _, status in ipairs(non_modified_statuses) do
            assert.are.equal(false, is_modified(status))
        end
    end)

    it("returns false for non-status values", function()
        local bad_statuses = {
            "",
            "some string",
            "UPPERCASE",
            "A",
            "AA ",
            " AA",
            "12",
        }
        for _, status in ipairs(bad_statuses) do
            assert.are.equal(false, is_modified(status))
        end
        assert.are.equal(false, is_modified(nil))
        --yeah
    end)
end)
