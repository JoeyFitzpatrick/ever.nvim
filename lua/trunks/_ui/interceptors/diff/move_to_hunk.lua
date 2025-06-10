local M = {}

function M.move_cursor_to_next_hunk(bufnr)
    local cursor = vim.api.nvim_win_get_cursor(0)
    local cursor_row, cursor_col = cursor[1], cursor[2]
    while cursor_row < vim.api.nvim_buf_line_count(bufnr) do
        -- We don't want to consider the current line, so start with the next line
        local line = vim.api.nvim_buf_get_lines(bufnr, cursor_row, cursor_row + 1, false)[1]
        if line:match("^@@") then
            vim.api.nvim_win_set_cursor(0, { cursor_row + 1, cursor_col })
            return
        end
        cursor_row = cursor_row + 1
    end
end

function M.move_cursor_to_previous_hunk(bufnr)
    local cursor = vim.api.nvim_win_get_cursor(0)
    local cursor_row, cursor_col = cursor[1], cursor[2]
    while cursor_row > 1 do
        -- We don't want to consider the current line, so start with the previous line
        local line = vim.api.nvim_buf_get_lines(bufnr, cursor_row - 2, cursor_row - 1, false)[1]
        if line:match("^@@") then
            vim.api.nvim_win_set_cursor(0, { cursor_row - 1, cursor_col })
            return
        end
        cursor_row = cursor_row - 1
    end
end

return M
