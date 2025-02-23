local M = {}

local function set_keymaps(bufnr)
    local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }

    vim.keymap.set("n", "q", function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end, keymap_opts)
end

---@param cmd string
M.render = function(cmd)
    local current_filename = vim.api.nvim_buf_get_name(0)
    cmd = cmd .. " " .. current_filename
    if not cmd:match("^git ") then
        cmd = "git " .. cmd
    end
    local bufnr = require("ever._ui.elements").new_buffer({ win_config = { split = "left" } })
    set_keymaps(bufnr)
    vim.api.nvim_set_option_value("wrap", false, { win = 0 })
    require("ever._ui.stream").stream_lines(bufnr, cmd, {
        [128] = function()
            vim.notify(string.format("%s not tracked by git", current_filename), vim.log.levels.ERROR)
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end,
    })
end

return M
