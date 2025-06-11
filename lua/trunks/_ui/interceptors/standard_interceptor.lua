local M = {}

---@param cmd string
function M.vim_render(cmd)
    if not cmd:match("^git ") then
        cmd = "git " .. cmd
    end
    local bufnr = require("trunks._ui.elements").new_buffer({ filetype = "git" })
    require("trunks._ui.keymaps.git_filetype_keymaps").set_keymaps(bufnr)
    require("trunks._ui.stream").stream_lines(bufnr, cmd, {})
end

---@param cmd string
function M.native_render(cmd)
    require("trunks._ui.elements").terminal(cmd, { insert = true, display_strategy = "full" })
end

M.render = M.vim_render

return M
