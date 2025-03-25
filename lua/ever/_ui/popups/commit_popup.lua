local M = {}

---@param bufnr integer
local function set_keymaps(bufnr)
    local keymaps = require("ever._ui.keymaps.base").get_keymaps(bufnr, "commit_popup", { popup = true })
    local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }
    local set = require("ever._ui.keymaps.set").safe_set_keymap

    local keymap_command_map = {
        [keymaps.commit] = "G commit",
        [keymaps.commit_amend] = "G commit --amend",
        [keymaps.commit_amend_reuse_message] = "G commit --amend --reuse-message HEAD --no-verify",
        [keymaps.commit_dry_run] = "G commit --dry-run",
        [keymaps.commit_no_verify] = "G commit --no-verify",
    }

    for keys, command in pairs(keymap_command_map) do
        set("n", keys, function()
            vim.api.nvim_buf_delete(bufnr, { force = true })
            vim.cmd(command)
        end, keymap_opts)
    end
end

---@return integer -- bufnr
function M.render()
    local bufnr = require("ever._ui.popups.popup").render_popup({
        ui_type = "commit_popup",
        buffer_name = "EverCommitPopup",
        title = "Commit",
    })
    set_keymaps(bufnr)
    return bufnr
end

return M
