-- Status rendering

local M = {}

local function get_status(line)
    return line:sub(1, 2)
end

--- Highlight status lines
---@param bufnr integer
---@param start_line integer
---@param lines string[]
local function highlight(bufnr, start_line, lines)
    local highlight_groups = require("lua.ever._constants.highlight_groups").highlight_groups
    for line_num, line in ipairs(lines) do
        local highlight_group
        local status = get_status(line)
        if require("lua.ever._core.git").is_staged(status) then
            highlight_group = highlight_groups.EVER_DIFF_ADD
        elseif require("lua.ever._core.git").is_modified(status) then
            highlight_group = highlight_groups.EVER_DIFF_MODIFIED
        else
            highlight_group = highlight_groups.EVER_DIFF_DELETE
        end
        vim.api.nvim_buf_add_highlight(bufnr, -1, highlight_group, line_num + start_line - 1, 0, 2)
    end
end

---@param bufnr integer
---@param opts? ever.UiRenderOpts
function M.render(bufnr, opts)
    opts = opts or {}
    local start_line = opts.start_line or 0
    local output = require("ever._core.run_cmd").run_cmd({ "git", "status", "--porcelain" })
    vim.api.nvim_buf_set_lines(bufnr, start_line or 0, -1, false, output)
    highlight(bufnr, start_line, output)
end

return M
