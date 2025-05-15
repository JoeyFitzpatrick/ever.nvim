---@class ever.RegisterOpts
---@field render_fn? fun()
---@field state? table<string, any>

---@class ever.RegisterOptsWithState
---@field render_fn? fun()
---@field state table<string, any>

---@class ever.DeregisterOpts
---@field skip_go_to_last_buffer? boolean

local M = {}

---@type table<integer, ever.RegisterOptsWithState>
M.buffers = {}

---@param bufnr integer
---@param opts ever.RegisterOpts
function M.register_buffer(bufnr, opts)
    if not opts.state then
        opts.state = {}
    end
    ---@diagnostic disable-next-line: assign-type-mismatch
    M.buffers[bufnr] = opts
end

---@param bufnr? integer
---@param opts ever.DeregisterOpts
function M.deregister_buffer(bufnr, opts)
    if not bufnr then
        return
    end
    M.buffers[bufnr] = nil
    if vim.api.nvim_buf_is_valid(bufnr) then
        if not opts.skip_go_to_last_buffer then
            -- Navigate to previous buffer before removing this buffer.
            -- This is to prevent issues where calling deregister in a
            -- split or tab closes that split or tab.
            pcall(function()
                vim.cmd("b#")
            end)
        end
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end
end

---@param bufnr? integer optional buffer to rerender first
function M.rerender_buffers(bufnr)
    -- Always rerender current buffer first if one isn't passed in
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local main_buffer = M.buffers[bufnr]
    if main_buffer and main_buffer.render_fn then
        main_buffer.render_fn()
    end
    for buf, opts in pairs(M.buffers) do
        if buf ~= bufnr and opts.render_fn then
            vim.schedule(opts.render_fn)
        end
    end
end

return M
