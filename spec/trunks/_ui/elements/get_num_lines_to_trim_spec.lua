local get_num_lines_to_trim = require("trunks._ui.elements")._get_num_lines_to_trim

describe("get_num_lines_to_trim", function()
    it("returns 1 when there is an empty line at the end of the output", function()
        local mock_lines = { "hello", "" }
        assert.are.same(1, get_num_lines_to_trim(mock_lines))
    end)
    it("returns 1 when there is a 'process exited' line at the end of the output", function()
        local mock_lines = { "hello", "[Process exited 0]" }
        assert.are.same(1, get_num_lines_to_trim(mock_lines))
    end)
    it("counts both empty lines and 'process exited' lines", function()
        local mock_lines = { "hello", "", "[Process exited 0]" }
        assert.are.same(2, get_num_lines_to_trim(mock_lines))
    end)
    it("returns 0 when there are no lines to trim", function()
        local mock_lines = { "hello", "goodbye" }
        assert.are.same(0, get_num_lines_to_trim(mock_lines))
    end)
    it("returns 0 when there are no lines", function()
        local mock_lines = {}
        assert.are.same(0, get_num_lines_to_trim(mock_lines))
    end)
end)
