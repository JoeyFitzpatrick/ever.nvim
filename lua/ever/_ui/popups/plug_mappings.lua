local M = {}

M.MAPPINGS = {
    EVER_COMMIT_POPUP = "<Plug>(Ever-commit-popup)",
    EVER_STASH_POPUP = "<Plug>(Ever-stash-popup)",
}

local function set_autocmds(bufnr)
    vim.api.nvim_create_autocmd("BufLeave", {
        buffer = bufnr,
        callback = function()
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end,
        group = vim.api.nvim_create_augroup("EverPopupLeave", { clear = true }),
    })
end

function M.setup_plug_mappings()
    vim.keymap.set("n", M.MAPPINGS.EVER_COMMIT_POPUP, function()
        local bufnr = require("ever._ui.popups.commit_popup").render()
        set_autocmds(bufnr)
    end)
    vim.keymap.set("n", M.MAPPINGS.EVER_STASH_POPUP, function()
        local bufnr = require("ever._ui.popups.stash_popup").render()
        set_autocmds(bufnr)
    end)
end

return M
