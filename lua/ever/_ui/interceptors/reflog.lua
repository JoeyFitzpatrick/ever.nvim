local M = {}

local function highlight(bufnr)
    for i, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
        local hash_start, hash_end = line:find("%x+")
        require("ever._ui.highlight").highlight_line(bufnr, "Identifier", i - 1, hash_start, hash_end)
        if not hash_start or not hash_end then
            return
        end
        local ref_start, ref_end = line:find(".+}", hash_end + 1)
        require("ever._ui.highlight").highlight_line(bufnr, "Keyword", i - 1, ref_start, ref_end)
    end
end

---@param bufnr integer
---@param line_num? integer
---@return { hash: string } | nil
local function get_line(bufnr, line_num)
    line_num = line_num or vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1]
    if line == "" then
        return nil
    end
    return { hash = line:match("%w+") }
end

---@param bufnr integer
local function set_keymaps(bufnr, opts)
    local keymaps = require("ever._ui.keymaps.base").get_ui_keymaps(bufnr, "reflog")
    local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }

    vim.keymap.set("n", keymaps.checkout, function()
        local line_data = get_line(bufnr)
        if not line_data then
            return
        end
        vim.cmd("G checkout " .. line_data.hash)
    end, keymap_opts)

    vim.keymap.set("n", keymaps.commit_details, function()
        local line_data = get_line(bufnr)
        if not line_data then
            return
        end
        require("ever._ui.commit_details").render(line_data.hash)
    end, keymap_opts)

    vim.keymap.set("n", keymaps.commit_info, function()
        local line_data = get_line(bufnr)
        if not line_data then
            return
        end
        require("ever._ui.elements").float(
            vim.api.nvim_create_buf(false, true),
            { title = "Git log " .. line_data.hash }
        )
        require("ever._ui.elements").terminal("log -n 1 " .. line_data.hash, { display_strategy = "full" })
    end, keymap_opts)

    vim.keymap.set("n", keymaps.show, function()
        local line_data = get_line(bufnr)
        if not line_data then
            return
        end
        require("ever._ui.elements").float(
            vim.api.nvim_create_buf(false, true),
            { title = "Git show " .. line_data.hash }
        )
        require("ever._ui.elements").terminal("show " .. line_data.hash, { display_strategy = "full", insert = true })
    end, keymap_opts)
end

---@param cmd string
function M.render(cmd)
    local bufnr = require("ever._ui.elements").new_buffer({
        buffer_name = os.tmpname() .. "EverReflog",
        filetype = "git",
        lines = function()
            return require("ever._core.run_cmd").run_cmd("git " .. cmd)
        end,
    })
    highlight(bufnr)
    set_keymaps(bufnr)
end

return M
