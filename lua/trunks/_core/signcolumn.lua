local M = {}

function M.initialize_signcolumns()
    local highlight_groups = require("trunks._constants.highlight_groups").highlight_groups
    local signcolumns = require("trunks._constants.signcolumns").signcolumns
    vim.fn.sign_define(signcolumns.trunks_PLUS, {
        text = "+",
        texthl = highlight_groups.trunks_DIFF_ADD,
    })
    vim.fn.sign_define(signcolumns.trunks_MINUS, {
        text = "-",
        texthl = highlight_groups.trunks_DIFF_REMOVE,
    })
end

return M
