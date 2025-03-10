local M = {}

function M.set_keymaps(bufnr)
    local keymaps = require("ever._ui.keymaps.base").get_ui_keymaps(bufnr, "diff", {})
    local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }

    vim.keymap.set("n", keymaps.next_hunk, function()
        require("ever._ui.interceptors.diff.move_to_hunk").move_cursor_to_next_hunk(bufnr)
    end, keymap_opts)

    vim.keymap.set("n", keymaps.previous_hunk, function()
        require("ever._ui.interceptors.diff.move_to_hunk").move_cursor_to_previous_hunk()
    end, keymap_opts)
end

return M
