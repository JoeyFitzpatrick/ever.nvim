---@class ever.RegisterOpts
---@field render_fn fun()

local M = {}

---@type table<integer, ever.RegisterOpts>
M.buffers = {}

---@param bufnr integer
---@param opts ever.RegisterOpts
function M.register_buffer(bufnr, opts)
    M.buffers[bufnr] = opts
end

---@param bufnr? integer
function M.deregister_buffer(bufnr)
    if not bufnr then
        return
    end
    M.buffers[bufnr] = nil
    if vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end
end

---@param bufnr? integer
function M.rerender_buffers(bufnr)
    local main_buffer = M.buffers[bufnr]
    if main_buffer then
        M.buffers[bufnr].render_fn(bufnr)
    end
    for buf, opts in pairs(M.buffers) do
        if buf ~= bufnr then
            vim.schedule(opts.render_fn)
        end
    end
end

return M
