local M = {}

---@param bufnr integer
local function set_keymaps(bufnr)
    local keymaps = require("trunks._ui.keymaps.base").get_keymaps(bufnr, "stash_popup", { popup = true })
    local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }
    local set = require("trunks._ui.keymaps.set").safe_set_keymap

    local keymap_command_map = {
        [keymaps.stash_all] = "G stash --include-untracked",
        [keymaps.stash_staged] = "G stash --staged",
    }

    for keys, command in pairs(keymap_command_map) do
        set("n", keys, function()
            vim.api.nvim_buf_delete(bufnr, { force = true })
            vim.ui.input({ prompt = "Stash message: " }, function(input)
                if not input then
                    return
                end
                if input:match("^%s*$") then
                    vim.cmd(command)
                else
                    vim.cmd(command .. " -m " .. require("trunks._core.texter").surround_with_quotes(input))
                end
            end)
        end, keymap_opts)
    end
end

---@return integer -- bufnr
function M.render()
    local bufnr = require("trunks._ui.popups.popup").render_popup({
        ui_type = "stash_popup",
        buffer_name = "TrunksStashPopup",
        title = "Stash",
    })
    set_keymaps(bufnr)
    return bufnr
end

return M
