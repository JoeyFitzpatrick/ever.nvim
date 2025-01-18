--- The main file that implements `status` outside of COMMAND mode.
---
---@module 'ever._commands.status.runner'
---

local M = {}

--- Print the `names`.
---
---@param names string[]? Some text to print out. e.g. `{"a", "b", "c"}`.
---
function M.run(names)
    local text

    if not names or vim.tbl_isempty(names) then
        text = ""
    else
        text = " " .. vim.fn.join(names, " ")
    end

    local bufnr = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(bufnr, true, { split = "below" })
    vim.fn.jobstart("git status" .. text, { term = true })
    vim.keymap.set("n", "p", function()
        local index = vim.api.nvim_win_get_cursor(win)[1]
        local line = vim.api.nvim_buf_get_lines(bufnr, index - 1, index, false)[1]
        vim.print(line)
    end, { buffer = bufnr })
end

return M
