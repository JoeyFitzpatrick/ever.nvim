local M = {}

function M.move_cursor_to_next_hunk(bufnr)
    local hunk = require("ever._ui.interceptors.diff.hunk").extract()
    if not hunk then
        local cursor = vim.api.nvim_win_get_cursor(0)
        for line_num, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, cursor[1] - 1, -1, false)) do
            if line:sub(1, 2) == "@@" then
                vim.api.nvim_win_set_cursor(0, { line_num, cursor[2] })
                return
            end
        end
        return
    end
    if hunk.next_hunk_start == nil then
        return
    end
    local cursor = vim.api.nvim_win_get_cursor(0)
    vim.api.nvim_win_set_cursor(0, { hunk.next_hunk_start, cursor[2] })
end

function M.move_cursor_to_previous_hunk()
    local hunk = require("ever._ui.interceptors.diff.hunk").extract()
    if not hunk or hunk.previous_hunk_start == nil then
        return
    end
    local cursor = vim.api.nvim_win_get_cursor(0)
    vim.api.nvim_win_set_cursor(0, { hunk.previous_hunk_start, cursor[2] })
end

return M
