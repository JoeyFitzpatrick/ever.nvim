local M = {}

---@param bufnr integer
local function set_terminal_keymaps(bufnr)
    local opts = { buffer = bufnr }

    vim.keymap.set("n", "q", function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end, opts)

    vim.keymap.set("n", "<enter>", function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end, opts)
end

--- Set the appropriate keymaps for a given command and element.
---@param bufnr integer
---@param element ever.ElementType -- Element type, e.g. "terminal"
function M.set_keymaps(bufnr, element)
    if element == "terminal" then
        set_terminal_keymaps(bufnr)
    end
end

return M
