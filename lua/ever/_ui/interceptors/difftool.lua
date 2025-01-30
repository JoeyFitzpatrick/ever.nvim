local M = {}

---@param cmd string
M.render = function(cmd)
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, bufnr)
    local output = require("ever._core.run_cmd").run_cmd("git diff --name-status")
    vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, output)
    vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })

    vim.keymap.set("n", "q", function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end, { buffer = bufnr })
end

return M
