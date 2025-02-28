local create_grep_qflist_item = require("ever._ui.interceptors.grep")._create_grep_qflist_item

describe("create grep qflist item", function()
    it("creates a qflist table from a line of grep output", function()
        local bufnr = -1
        local input = "df84f610016cac61c827c9c78669b2b4139061c9:lua/ever/health.lua:369:51:    "
            .. 'end, "a table. e.g. { goodnight_moon = {...}, hello_world = {...}}")'
        ---@type ever.GrepQflistItem
        local expected = {
            bufnr = bufnr,
            lnum = 369,
            col = 51,
        }
        assert.are.same(expected, create_grep_qflist_item(bufnr, input))
    end)
end)
