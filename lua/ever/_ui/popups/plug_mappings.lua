local M = {}

M.MAPPINGS = {
    EVER_COMMIT_POPUP = "<Plug>(Ever-commit-popup)",
}

function M.setup_plug_mappings()
    vim.keymap.set("n", M.MAPPINGS.EVER_COMMIT_POPUP, function()
        print("in commit popup")
    end)
end

return M
