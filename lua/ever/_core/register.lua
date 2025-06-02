---@class ever.RegisterOpts
---@field render_fn? fun()
---@field state? table<string, any>
---@field win? integer

---@class ever.RegisterOptsWithState
---@field render_fn? fun()
---@field state table<string, any>
---@field win? integer

---@class ever.DeregisterOpts
---@field skip_go_to_last_buffer? boolean

local M = {}

---@type table<integer, ever.RegisterOptsWithState>
M.buffers = {}

---@type table<integer, integer>
M.last_non_ever_buffer_for_win = {}

---@param bufnr integer
---@param opts ever.RegisterOpts
function M.register_buffer(bufnr, opts)
    if not opts.state then
        opts.state = {}
    end
    if not opts.win then
        opts.win = vim.api.nvim_get_current_win()
    end
    ---@diagnostic disable-next-line: assign-type-mismatch
    M.buffers[bufnr] = opts
end

---@param bufnr integer
local function navigate_to_last_non_ever_buffer(bufnr)
    local win = vim.fn.bufwinid(bufnr)
    if not win then
        return
    end
    local buf_to_navigate_to = M.last_non_ever_buffer_for_win[win]
    if not buf_to_navigate_to or not vim.api.nvim_buf_is_valid(buf_to_navigate_to) then
        return
    end
    vim.api.nvim_win_set_buf(win, M.last_non_ever_buffer_for_win[win])
end

---@param win integer
local function delete_ever_buffers_for_win(win)
    for bufnr, opts in pairs(M.buffers) do
        if opts.win == win then
            M.deregister_buffer(bufnr, { skip_go_to_last_buffer = true })
        end
    end
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
            navigate_to_last_non_ever_buffer(bufnr)
            delete_ever_buffers_for_win(vim.api.nvim_get_current_win())
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
