local create_box_table = require("ever._ui.home")._create_box_table

describe("create box table", function()
    it("returns the correct start/end indices for the box", function()
        local _, indices_result = create_box_table({ "Status" })
        local expected = {
            {
                { start = 5, ending = 32 },
                { start = 5, ending = 16 },
                { start = 5, ending = 32 },
            },
        }
        assert.are.same(expected, indices_result)
    end)
    it("returns the correct start/end indices for the box", function()
        local _, indices_result = create_box_table({ "Status", "Branch", "Log", "Stash" })
        local expected = {
            {
                { start = 5, ending = 32 },
                { start = 5, ending = 16 },
                { start = 5, ending = 32 },
            },
            {
                { start = 37, ending = 64 },
                { start = 21, ending = 32 },
                { start = 37, ending = 64 },
            },
            {
                { start = 69, ending = 93 },
                { start = 37, ending = 47 },
                { start = 69, ending = 93 },
            },
            {
                { start = 98, ending = 122 },
                { start = 52, ending = 62 },
                { start = 98, ending = 122 },
            },
        }
        assert.are.same(expected, indices_result)
    end)
end)
