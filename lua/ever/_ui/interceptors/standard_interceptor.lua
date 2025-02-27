local M = {}

local function set_keymaps(bufnr)
    local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }

    vim.keymap.set("n", "q", function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end, keymap_opts)
end

---@param cmd string
function M.vim_render(cmd)
    if not cmd:match("^git ") then
        cmd = "git " .. cmd
    end
    local bufnr = require("ever._ui.elements").new_buffer({ filetype = "git" })
    set_keymaps(bufnr)
    require("ever._ui.stream").stream_lines(bufnr, cmd, {})
end

---@param cmd string
function M.native_render(cmd)
    require("ever._ui.elements").terminal(cmd, { insert = true, display_strategy = "full" })
end

M.render = M.native_render

return M
