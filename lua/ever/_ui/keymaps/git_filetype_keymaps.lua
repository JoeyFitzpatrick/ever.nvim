---@class ever.GitFiletypeLineData
---@field commit? string

local M = {}

---@param bufnr
---@return ever.GitFiletypeLineData | nil
local function get_line(bufnr)
    local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_buf_get_lines(bufnr, cursor_row - 1, cursor_row, false)[1]
    if line:match("^commit") then
        return { commit = line:match("%x+", 8) }
    end
    return nil
end

---@param bufnr integer
function M.set_keymaps(bufnr)
    local keymaps = require("ever._ui.keymaps.base").get_keymaps(bufnr, "git_filetype", {})
    local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }
    local set = require("ever._ui.keymaps.set").safe_set_keymap

    set("n", keymaps.show_details, function()
        local line_data = get_line(bufnr)
        if not line_data or not line_data.commit then
            return
        end
        require("ever._ui.commit_details").render(line_data.commit, false)
    end, keymap_opts)
end

return M
