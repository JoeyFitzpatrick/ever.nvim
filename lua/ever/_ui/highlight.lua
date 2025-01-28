local M = {}

--- Make highlighting a line a little easier.
---@param bufnr integer
---@param highlight_group string
---@param line_num integer
---@param start? integer
---@param finish? integer
function M.highlight_line(bufnr, highlight_group, line_num, start, finish)
    if start and finish then
        vim.api.nvim_buf_add_highlight(bufnr, -1, highlight_group, line_num, start - 1, finish)
    end
end

return M
