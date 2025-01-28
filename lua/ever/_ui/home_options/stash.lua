local M = {}

--- Highlight stash lines
---@param bufnr integer
---@param start_line integer
---@param lines string[]
local function highlight(bufnr, start_line, lines)
    local highlight_line = require("ever._ui.highlight").highlight_line
    for i, line in ipairs(lines) do
        local line_num = i + start_line - 1
        local stash_index_start, stash_index_end = line:find("^%S+")
        highlight_line(bufnr, "Keyword", line_num, stash_index_start, stash_index_end)
        local date_start, date_end = line:find(".+ago", stash_index_end + 1)
        highlight_line(bufnr, "Function", line_num, date_start, date_end)
        local branch_start, branch_end = line:find(" .+:", date_end + 1)
        highlight_line(bufnr, "Removed", line_num, branch_start, branch_end)
    end
end

---@param bufnr integer
---@param opts ever.UiRenderOpts
function M.render(bufnr, opts)
    local start_line = opts.start_line or 0
    local output = require("ever._core.run_cmd").run_cmd({
        "git",
        "stash",
        "list",
        "--pretty=format:%<(12)%gd %<(18)%cr   %<(25)%s",
    })
    vim.api.nvim_buf_set_lines(bufnr, start_line, -1, false, output)
    highlight(bufnr, start_line, output)
end

return M
