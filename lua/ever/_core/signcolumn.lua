local M = {}

function M.initialize_signcolumns()
    local highlight_groups = require("ever._constants.highlight_groups").highlight_groups
    local signcolumns = require("ever._constants.signcolumns").signcolumns
    vim.fn.sign_define(signcolumns.EVER_PLUS, {
        text = "+",
        texthl = highlight_groups.EVER_DIFF_ADD,
    })
    vim.fn.sign_define(signcolumns.EVER_MINUS, {
        text = "-",
        texthl = highlight_groups.EVER_DIFF_REMOVE,
    })
end

return M
