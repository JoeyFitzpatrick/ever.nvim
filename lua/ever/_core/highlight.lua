local M = {}

function M.initialize_highlights()
    local hlgroup = require("lua.ever._constants.highlight_groups").highlight_groups
    local is_light_background = vim.api.nvim_get_option_value("background", {}) == "light"
    vim.api.nvim_set_hl(0, hlgroup.EVER_DIFF_ADD, { fg = is_light_background and "NvimDarkGreen" or "#43FD1A" })
    vim.api.nvim_set_hl(0, hlgroup.EVER_DIFF_MODIFIED, { fg = is_light_background and "NvimDarkYellow" or "#FCDE1F" })
    vim.api.nvim_set_hl(0, hlgroup.EVER_DIFF_DELETE, { fg = is_light_background and "NvimDarkRed" or "#EE5135" })
end

return M
