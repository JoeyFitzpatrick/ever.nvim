local M = {}

function M.get_visual_line_nums()
    -- move back to normal mode to access most recent visual line nums
    -- this is a workaround, as 'getpos' won't return correct lines until visual mode is exited
    local back_to_n = vim.api.nvim_replace_termcodes("<esc>", true, false, true)
    vim.api.nvim_feedkeys(back_to_n, "x", false)
    local start = vim.fn.getpos("'<")[2] - 1
    local ending = vim.fn.getpos("'>")[2]
    return start, ending
end

return M
