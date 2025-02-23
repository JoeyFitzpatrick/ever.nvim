local M = {}

local function set_keymaps(bufnr)
    local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }

    vim.keymap.set("n", "q", function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end, keymap_opts)
end

---@param cmd string
M.render = function(cmd)
    if not cmd:match("^git ") then
        cmd = "git " .. cmd
    end
    local bufnr = require("ever._ui.elements").new_buffer({ filetype = "git" })
    set_keymaps(bufnr)
    require("ever._ui.stream").stream_lines(bufnr, cmd, {})
end

return M
