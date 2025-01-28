-- Log rendering

local M = {}

--- Highlight log (commit) lines
---@param bufnr integer
---@param start_line integer
---@param lines string[]
local function highlight(bufnr, start_line, lines)
    local highlight_line = require("ever._ui.highlight").highlight_line
    for i, line in ipairs(lines) do
        local line_num = i + start_line - 1
        local hash_start, hash_end = line:find("^󰜘 %w+")
        highlight_line(bufnr, "MatchParen", line_num, hash_start, hash_end)
        local date_start, date_end = line:find(".+ago", hash_end + 1)
        highlight_line(bufnr, "Function", line_num, date_start, date_end)
        local author_start, author_end = line:find("%s%s+(.-)%s%s+", date_end + 1)
        highlight_line(bufnr, "Identifier", line_num, author_start, author_end)
    end
end

---@param bufnr integer
---@param opts ever.UiRenderOpts
function M.render(bufnr, opts)
    local start_line = opts.start_line or 0
    local output = require("ever._core.run_cmd").run_cmd({
        "git",
        "log",
        "--pretty=format:󰜘 %h %<(25)%cr %<(25)%an %<(25)%s",
    })
    vim.api.nvim_buf_set_lines(bufnr, start_line, -1, false, output)
    highlight(bufnr, start_line, output)
end

return M
