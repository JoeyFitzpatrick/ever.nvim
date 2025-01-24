-- Status rendering

local M = {}

---@param bufnr integer
---@param opts? ever.UiRenderOpts
function M.render(bufnr, opts)
    opts = opts or {}
    local output = require("ever._core.run_cmd").run_cmd({ "git", "status", "--porcelain" })
    vim.api.nvim_buf_set_lines(bufnr, opts.start_line or 0, -1, false, output)
end

return M
