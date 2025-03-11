local M = {}

--- A helper to accomplish two things:
--- 1. Skip setting keymap if lhs is nil
--- 2. Assert that opts are passed in so we don't forget to pass them in
---@param mode string | string[]
---@param lhs? string
---@param rhs string | function
---@param opts vim.keymap.set.Opts
function M.safe_set_keymap(mode, lhs, rhs, opts)
    if not lhs then
        return
    end
    vim.keymap.set(mode, lhs, rhs, opts)
end

return M
