local M = {}

local function set_keymaps(bufnr)
    local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }

    vim.keymap.set("n", "q", function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end, keymap_opts)
end

---@param cmd string
M.render = function(cmd)
    local bufnr = require("ever._ui.elements").new_buffer({
        filetype = "git",
        lines = function()
            -- "git" is not included in commands from ":G"
            return require("ever._core.run_cmd").run_cmd("git " .. cmd)
        end,
    })
    set_keymaps(bufnr)
end

return M
