local M = {}

---@return integer, integer
function M.get_visual_line_nums()
    -- move back to normal mode to access most recent visual line nums
    -- this is a workaround, as 'getpos' won't return correct lines until visual mode is exited
    local back_to_n = vim.api.nvim_replace_termcodes("<esc>", true, false, true)
    vim.api.nvim_feedkeys(back_to_n, "x", false)
    local start = vim.fn.getpos("'<")[2] - 1
    local ending = vim.fn.getpos("'>")[2]
    return start, ending
end

--- Return the text from the last visual selection.
---@return string
function M.get_visual_selection()
    local text = ""
    local maxcol = vim.v.maxcol
    local region = vim.region(0, "'<", "'>", vim.fn.visualmode(), true)
    for line, cols in vim.spairs(region) do
        local endcol = cols[2] == maxcol and -1 or cols[2]
        local chunk = vim.api.nvim_buf_get_text(0, line, cols[1], line, endcol, {})[1]
        text = ("%s%s"):format(text, chunk)
    end
    return text
end

return M
