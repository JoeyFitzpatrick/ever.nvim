local M = {}

function M.set_keymaps(bufnr)
    local keymaps = require("trunks._ui.keymaps.base").get_keymaps(bufnr, "diff", {})
    local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }
    local set = require("trunks._ui.keymaps.set").safe_set_keymap

    set("n", keymaps.next_hunk, function()
        require("trunks._ui.interceptors.diff.move_to_hunk").move_cursor_to_next_hunk(bufnr)
    end, keymap_opts)

    set("n", keymaps.previous_hunk, function()
        require("trunks._ui.interceptors.diff.move_to_hunk").move_cursor_to_previous_hunk(bufnr)
    end, keymap_opts)
end

return M
