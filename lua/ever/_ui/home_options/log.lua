-- Log rendering

local M = {}

---@param bufnr integer
---@param opts? ever.UiRenderOpts
function M.render(bufnr, opts)
    opts = opts or {}
    local output = require("lua.ever._core.run_cmd").run_cmd({
        "git",
        "log",
        "--pretty=format:%h %<(25)%cr %<(25)%an %<(25)%s",
    })
    vim.api.nvim_buf_set_lines(bufnr, opts.start_line or 0, -1, false, output)
end

return M
