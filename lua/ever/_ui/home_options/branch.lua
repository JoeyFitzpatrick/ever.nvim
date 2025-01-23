--- Branch rendering

local M = {}

---@param bufnr integer
---@param opts? ever.UiRenderOpts
function M.render(bufnr, opts)
    opts = opts or {}
    local output = require("lua.ever._core.run_cmd").run_cmd({ "git", "branch" })
    vim.api.nvim_buf_set_lines(bufnr, opts.start_line or 0, -1, false, output)
end

return M
