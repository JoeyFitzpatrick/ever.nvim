---@class ever.AutoDisplayOpts
---@field generate_cmd fun(bufnr: integer): string?
---@field get_current_diff fun(bufnr: integer): string
---@field strategy ever.Strategy

local M = {}

---@param state table<string, any>
---@param ui_type string
local function clear_state(state, ui_type)
    if state.diff_bufnr then
        require("ever._core.register").deregister_buffer(state.diff_bufnr)
    end
    state.diff_bufnr = nil
    state.diff_channel_id = nil
    state.current_diff = nil
    state.display_auto_display = require("ever._core.configuration").DATA[ui_type].auto_display_on
end

local function set_diff_buffer_autocmds(diff_bufnr, original_bufnr, ui_type)
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
        desc = "Stop insert mode on buf enter",
        buffer = diff_bufnr,
        command = "stopinsert",
        group = vim.api.nvim_create_augroup(string.format("Ever%sStopInsert", ui_type), { clear = false }),
    })
    vim.api.nvim_create_autocmd("BufHidden", {
        desc = "Close open diffs when buffer is hidden",
        buffer = original_bufnr,
        callback = function()
            require("ever._core.register").deregister_buffer(diff_bufnr)
            local buf = require("ever._core.register").buffers[original_bufnr]
            if buf then
                clear_state(buf.state, ui_type)
            end
        end,
        group = vim.api.nvim_create_augroup(string.format("Ever%sCloseAutoDisplay", ui_type), { clear = true }),
    })
    vim.api.nvim_create_autocmd("BufHidden", {
        desc = "Clean up diff variables",
        buffer = diff_bufnr,
        callback = function()
            local state = require("ever._core.register").buffers[original_bufnr].state
            state.diff_bufnr = nil
            state.diff_channel_id = nil
            state.current_diff = nil
        end,
    })
end

---@param bufnr integer
---@param ui_type string
---@param auto_display_opts ever.AutoDisplayOpts
local function set_autocmds(bufnr, ui_type, auto_display_opts)
    -- TODO: capitalize first letter of ui_type,
    -- and every letter after an underscore
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end
    vim.api.nvim_create_autocmd("CursorMoved", {
        desc = "Diff the file under the cursor",
        buffer = bufnr,
        callback = function()
            local state = require("ever._core.register").buffers[bufnr].state
            if not state.display_auto_display then
                return
            end
            local current_diff = auto_display_opts.get_current_diff(bufnr)
            if not current_diff or current_diff == state.current_diff then
                return
            end
            local diff_cmd = auto_display_opts.generate_cmd(bufnr)
            state.current_diff = current_diff
            if state.diff_bufnr then
                vim.api.nvim_buf_delete(state.diff_bufnr, { force = true })
                state.diff_bufnr = nil
            end
            local win = vim.api.nvim_get_current_win()
            state.diff_channel_id, state.diff_bufnr =
                require("ever._ui.elements").terminal(diff_cmd, auto_display_opts.strategy)
            set_diff_buffer_autocmds(state.diff_bufnr, bufnr, ui_type)
            vim.api.nvim_set_current_win(win)
        end,
        group = vim.api.nvim_create_augroup(string.format("Ever%sAutoDisplay", ui_type), { clear = true }),
    })
end

--- Create an auto_display for the given buffer.
--- Note that the buffer must be registered to use auto_display.
---@param bufnr integer
---@param ui_type string
---@param auto_display_opts ever.AutoDisplayOpts
function M.create_auto_display(bufnr, ui_type, auto_display_opts)
    local register = require("ever._core.register")
    if not register.buffers[bufnr] then
        return
    end
    assert(require("ever._core.configuration").DATA[ui_type], "Couldn't find config for ui type: " .. ui_type)

    local buf = require("ever._core.register").buffers[bufnr]
    clear_state(buf.state, ui_type)
    set_autocmds(bufnr, ui_type, auto_display_opts)
end

return M
