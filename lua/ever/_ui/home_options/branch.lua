--- Branch rendering

local M = {}

--- Highlight branch lines
---@param bufnr integer
---@param start_line integer
---@param lines string[]
local function highlight(bufnr, start_line, lines)
    local highlight_groups = require("lua.ever._constants.highlight_groups").highlight_groups
    for line_num, line in ipairs(lines) do
        if line:match("^%*") then
            vim.api.nvim_buf_add_highlight(bufnr, -1, highlight_groups.EVER_DIFF_ADD, line_num + start_line - 1, 2, -1)
            return
        end
    end
end

---@param bufnr integer
---@param opts ever.UiRenderOpts
function M.render(bufnr, opts)
    local start_line = opts.start_line or 0
    local output = require("ever._core.run_cmd").run_cmd({ "git", "branch" })
    vim.api.nvim_buf_set_lines(bufnr, start_line, -1, false, output)
    highlight(bufnr, start_line, output)
end

return M
