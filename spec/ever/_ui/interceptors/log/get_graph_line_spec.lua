local get_graph_line = require("ever._ui.home_options.log")._get_graph_line

local function mock_nvim_fns(mock_lines, mock_cursor_line_num)
    vim.api.nvim_buf_get_lines = function()
        return mock_lines
    end
    vim.api.nvim_win_get_cursor = function()
        return { mock_cursor_line_num, 0 }
    end
end

describe("get_graph_line", function()
    it("should parse a commit hash from a git log --graph line", function()
        mock_nvim_fns({
            "*     * 5ccddca 22:20:46 11-05-2025 Joey Fitzpatrick (HEAD -> main)",
            "│               docs: credit vendored plugins and inspiring tools",
        }, 1)
        assert.are.equal("5ccddca", get_graph_line(0, 0).hash)
    end)

    it("should parse a commit hash from a line below a hash", function()
        mock_nvim_fns({
            "*     * 5ccddca 22:20:46 11-05-2025 Joey Fitzpatrick (HEAD -> main)",
            "│               docs: credit vendored plugins and inspiring tools",
        }, 2)
        assert.are.equal("5ccddca", get_graph_line(0, 0).hash)
    end)

    it("should parse a commit hash from a graph with multiple merges", function()
        mock_nvim_fns({
            "│ │ M           5f669b9 15:39:34 09-05-2025 Joey F (origin/some-branch)",
            "│ ├─┤                   Merge branch 'master' into some-branch",
        }, 1)
        assert.are.equal("5f669b9", get_graph_line(0, 0).hash)
    end)
end)
