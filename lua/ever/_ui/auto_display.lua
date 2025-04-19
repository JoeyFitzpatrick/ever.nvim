---@class ever.AutoDisplayOpts
---@field generate_cmd fun(bufnr: integer): string?
---@field get_current_diff fun(bufnr: integer): string?
---@field strategy ever.Strategy

local M = {}

---@param state table<string, any>
---@param ui_type string
---@param display_auto_display? boolean
local function clear_state(state, ui_type, display_auto_display)
    if state.diff_bufnr and vim.api.nvim_buf_is_valid(state.diff_bufnr) then
        vim.api.nvim_buf_delete(state.diff_bufnr, { force = true })
    end
    state.diff_bufnr = nil
    state.diff_channel_id = nil
    state.current_diff = nil

    if display_auto_display == nil then
        state.display_auto_display = require("ever._core.configuration").DATA[ui_type].auto_display_on
    else
        state.display_auto_display = display_auto_display
    end
end

local function set_diff_buffer_autocmds(diff_bufnr, original_bufnr, ui_type)
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
        desc = "Stop insert mode on buf enter",
        buffer = diff_bufnr,
        command = "stopinsert",
        group = vim.api.nvim_create_augroup(string.format("Ever%sStopInsert", ui_type), { clear = false }),
    })
    vim.api.nvim_create_autocmd("BufHidden", {
        desc = "Close open diffs and clean up diff variables",
        buffer = original_bufnr,
        callback = function()
            local buf = require("ever._core.register").buffers[original_bufnr]
            if buf then
                clear_state(buf.state, ui_type)
            end
            require("ever._core.register").deregister_buffer(diff_bufnr, {})
        end,
        group = vim.api.nvim_create_augroup(string.format("Ever%sCloseAutoDisplay", ui_type), { clear = true }),
    })
end

---@param diff_bufnr integer
---@param original_bufnr integer
local function set_diff_buffer_keymaps(diff_bufnr, original_bufnr)
    require("ever._ui.keymaps.set").safe_set_keymap("n", "q", function()
        require("ever._core.register").deregister_buffer(diff_bufnr, { skip_go_to_last_buffer = true })
        require("ever._core.register").deregister_buffer(original_bufnr, {})
    end, { buffer = diff_bufnr })
end

---@param bufnr integer
---@param ui_type string
---@param auto_display_opts ever.AutoDisplayOpts
local function render_auto_display(bufnr, ui_type, auto_display_opts)
    local state = require("ever._core.register").buffers[bufnr].state
    local current_diff = auto_display_opts.get_current_diff(bufnr)
    if not current_diff then
        clear_state(state, ui_type, true)
        return
    end
    if current_diff == state.current_diff then
        return
    end
    local diff_cmd = auto_display_opts.generate_cmd(bufnr)
    if not diff_cmd then
        return
    end
    state.current_diff = current_diff
    if state.diff_bufnr then
        vim.api.nvim_buf_delete(state.diff_bufnr, { force = true })
        state.diff_bufnr = nil
    end
    local win = vim.api.nvim_get_current_win()
    state.diff_channel_id, state.diff_bufnr =
        require("ever._ui.elements").terminal(diff_cmd, auto_display_opts.strategy)
    set_diff_buffer_autocmds(state.diff_bufnr, bufnr, ui_type)
    set_diff_buffer_keymaps(state.diff_bufnr, bufnr)
    vim.api.nvim_set_current_win(win)
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
    vim.api.nvim_create_autocmd({ "CursorMoved", "BufEnter" }, {
        desc = "Diff the file under the cursor",
        buffer = bufnr,
        callback = function()
            local state = require("ever._core.register").buffers[bufnr].state
            if not state.display_auto_display then
                return
            end
            render_auto_display(bufnr, ui_type, auto_display_opts)
        end,
        group = vim.api.nvim_create_augroup(string.format("Ever%sAutoDisplay", ui_type), { clear = true }),
    })
end

---@param bufnr integer
---@param ui_type string
---@param auto_display_opts ever.AutoDisplayOpts
local function set_keymaps(bufnr, ui_type, auto_display_opts)
    local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }
    local registered_buffer = require("ever._core.register").buffers[bufnr]
    if not registered_buffer then
        return
    end
    local set = require("ever._ui.keymaps.set").safe_set_keymap
    local keymaps = require("ever._core.configuration").DATA.auto_display.keymaps

    set("n", keymaps.toggle_auto_display, function()
        if registered_buffer.state.display_auto_display then
            clear_state(registered_buffer.state, ui_type, false)
        else
            registered_buffer.state.display_auto_display = true
            render_auto_display(bufnr, ui_type, auto_display_opts)
        end
    end, keymap_opts)

    set("n", keymaps.scroll_diff_down, function()
        if registered_buffer.state.diff_bufnr and registered_buffer.state.diff_channel_id then
            pcall(vim.api.nvim_chan_send, registered_buffer.state.diff_channel_id, "jj")
        end
    end, keymap_opts)

    set("n", keymaps.scroll_diff_up, function()
        if registered_buffer.state.diff_bufnr and registered_buffer.state.diff_channel_id then
            pcall(vim.api.nvim_chan_send, registered_buffer.state.diff_channel_id, "kk")
        end
    end, keymap_opts)
end

--- Create an auto_display for the given buffer.
--- Note that the buffer must be registered to use auto_display.
---@param bufnr integer
---@param ui_type string
---@param auto_display_opts ever.AutoDisplayOpts
function M.create_auto_display(bufnr, ui_type, auto_display_opts)
    local register = require("ever._core.register")
    if not register.buffers[bufnr] then
        register.register_buffer(bufnr, {})
    end
    -- We need this check to ensure that we have an "auto_display_on" toggle in config
    assert(require("ever._core.configuration").DATA[ui_type], "Couldn't find config for ui type: " .. ui_type)

    local buf = require("ever._core.register").buffers[bufnr]
    if buf then
        clear_state(buf.state, ui_type)
    end
    set_keymaps(bufnr, ui_type, auto_display_opts)
    set_autocmds(bufnr, ui_type, auto_display_opts)
end

---@param bufnr integer
---@param ui_type string
function M.close_auto_display(bufnr, ui_type)
    local buf = require("ever._core.register").buffers[bufnr]
    if not buf then
        return
    end
    clear_state(buf.state, ui_type)
end

return M
