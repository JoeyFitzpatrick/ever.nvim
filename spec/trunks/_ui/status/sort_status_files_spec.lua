local sort_status_files = require("trunks._ui.home_options.status")._sort_status_files

describe("sort status files", function()
    it("sorts a list of status files by filepath, not status", function()
        local files = {
            "A  lastfile",
            "?? firstfile",
        }
        sort_status_files(files)
        local expected = {
            "?? firstfile",
            "A  lastfile",
        }
        assert.are.same(files, expected)
    end)
end)
