-- Commit details

---@class ever.CommitDetailsLineData
---@field filename string
---@field safe_filename string

local M = {}

local DIFF_BUFNR = nil
local DIFF_CHANNEL_ID = nil
local CURRENT_DIFF_FILE = nil
local DISPLAY_AUTODIFF = require("ever._core.configuration").DATA["commit_details"].auto_display_on

---@param bufnr integer
---@param i integer
---@param line string
local function highlight_line(bufnr, i, line)
    local start = line:find("|")
    if not start then
        return
    end
    local num_lines_changed_start, num_lines_changed_end = line:find("%d+", start)
    require("ever._ui.highlight").highlight_line(
        bufnr,
        "Keyword",
        i - 1,
        num_lines_changed_start,
        num_lines_changed_end
    )
    local hl_groups = require("ever._constants.highlight_groups").highlight_groups
    local plus_start, plus_end = line:find("%++", start)
    require("ever._ui.highlight").highlight_line(bufnr, hl_groups.EVER_DIFF_ADD, i - 1, plus_start, plus_end)
    local minus_start, minus_end = line:find("%-+", start)
    require("ever._ui.highlight").highlight_line(bufnr, hl_groups.EVER_DIFF_REMOVE, i - 1, minus_start, minus_end)
end

---@param bufnr integer
---@param commit string
function M.set_lines(bufnr, commit)
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end
    vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
    local commit_data = require("ever._core.run_cmd").run_cmd("git show --stat=10000 --stat-graph-width=40 " .. commit)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, commit_data)
    vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
    for i, line in ipairs(commit_data) do
        highlight_line(bufnr, i, line)
    end
    for i, line in ipairs(commit_data) do
        if line:match("^%s%S") then
            vim.api.nvim_win_set_cursor(0, { i, 0 })
            return
        end
    end
end

---@param bufnr integer
---@param line_num? integer
---@return ever.CommitDetailsLineData | nil
function M.get_line(bufnr, line_num)
    line_num = line_num or vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1]
    local filename = line:match("%S+", 1)
    if not filename then
        return nil
    end
    return { filename = filename, safe_filename = "'" .. filename .. "'" }
end

---@param bufnr integer
---@param commit string
---@param is_stash? boolean
local function set_keymaps(bufnr, commit, is_stash)
    local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }
    local keymaps = require("ever._ui.keymaps.base").get_keymaps(
        bufnr,
        "commit_details",
        { open_file_keymaps = true, auto_display_keymaps = true }
    )
    local set = require("ever._ui.keymaps.set").safe_set_keymap

    set("n", keymaps.toggle_auto_display, function()
        if DISPLAY_AUTODIFF then
            require("ever._core.register").deregister_buffer(DIFF_BUFNR)
            DIFF_BUFNR = nil
            DISPLAY_AUTODIFF = false
        else
            DISPLAY_AUTODIFF = true
            M._display_auto_display(bufnr, commit, is_stash)
        end
    end, keymap_opts)

    set("n", keymaps.open_in_current_window, function()
        local line_data = M.get_line(bufnr)
        if not line_data then
            return
        end
        require("ever._core.open_file").open_file_in_current_window(line_data.filename, commit)
    end, keymap_opts)

    set("n", keymaps.open_in_horizontal_split, function()
        local line_data = M.get_line(bufnr)
        if not line_data then
            return
        end
        if DIFF_BUFNR and vim.api.nvim_buf_is_valid(DIFF_BUFNR) then
            vim.api.nvim_buf_delete(DIFF_BUFNR, { force = true })
            DIFF_BUFNR = nil
        end
        require("ever._core.open_file").open_file_in_split(line_data.filename, commit, "below")
    end, keymap_opts)

    set("n", keymaps.open_in_new_tab, function()
        local line_data = M.get_line(bufnr)
        if not line_data then
            return
        end
        require("ever._core.open_file").open_file_in_tab(line_data.filename, commit)
    end, keymap_opts)

    set("n", keymaps.open_in_vertical_split, function()
        local line_data = M.get_line(bufnr)
        if not line_data then
            return
        end
        if DIFF_BUFNR and vim.api.nvim_buf_is_valid(DIFF_BUFNR) then
            vim.api.nvim_buf_delete(DIFF_BUFNR, { force = true })
            DIFF_BUFNR = nil
        end
        require("ever._core.open_file").open_file_in_split(line_data.filename, commit, "right")
    end, keymap_opts)

    set("n", keymaps.scroll_diff_down, function()
        if DIFF_BUFNR and DIFF_CHANNEL_ID then
            pcall(vim.api.nvim_chan_send, DIFF_CHANNEL_ID, "jj")
        end
    end, keymap_opts)

    set("n", keymaps.scroll_diff_up, function()
        if DIFF_BUFNR and DIFF_CHANNEL_ID then
            pcall(vim.api.nvim_chan_send, DIFF_CHANNEL_ID, "kk")
        end
    end, keymap_opts)

    set("n", keymaps.show_all_changes, function()
        vim.cmd("G show " .. commit)
    end, keymap_opts)
end

local function set_diff_buffer_autocmds(diff_bufnr)
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
        desc = "Stop insert mode on buf enter",
        buffer = diff_bufnr,
        command = "stopinsert",
        group = vim.api.nvim_create_augroup("EverCommitDetailsUi", { clear = false }),
    })
    vim.api.nvim_create_autocmd("BufHidden", {
        desc = "Clean up diff variables",
        buffer = diff_bufnr,
        callback = function()
            DIFF_BUFNR = nil
            DIFF_CHANNEL_ID = nil
            CURRENT_DIFF_FILE = nil
        end,
    })
end

function M._display_auto_display(bufnr, commit, is_stash)
    local line_data = M.get_line(bufnr)
    if not line_data or line_data.filename == CURRENT_DIFF_FILE then
        return
    end
    CURRENT_DIFF_FILE = line_data.filename
    if DIFF_BUFNR then
        vim.api.nvim_buf_delete(DIFF_BUFNR, { force = true })
        DIFF_BUFNR = nil
        DIFF_CHANNEL_ID = nil
    end
    local win = vim.api.nvim_get_current_win()
    local cmd = "show -p " .. commit .. " -- " .. line_data.safe_filename
    if is_stash then
        cmd = string.format("diff %s^1 %s -- %s", commit, commit, line_data.safe_filename)
    end
    DIFF_CHANNEL_ID =
        require("ever._ui.elements").terminal(cmd, { display_strategy = "below", win_size = 0.67, insert = false })
    DIFF_BUFNR = vim.api.nvim_get_current_buf()
    set_diff_buffer_autocmds(DIFF_BUFNR)
    vim.api.nvim_set_current_win(win)
end

---@param bufnr integer
---@param commit string
---@param is_stash? boolean
local function set_autocmds(bufnr, commit, is_stash)
    vim.api.nvim_create_autocmd("CursorMoved", {
        desc = "Diff the file under the cursor",
        buffer = bufnr,
        callback = function()
            if not DISPLAY_AUTODIFF then
                return
            end
            M._display_auto_display(bufnr, commit, is_stash)
        end,
        group = vim.api.nvim_create_augroup("EverCommitDetailsAutoDiff", { clear = true }),
    })

    vim.api.nvim_create_autocmd("BufHidden", {
        desc = "Close open diffs when buffer is hidden",
        buffer = bufnr,
        callback = function()
            if DIFF_BUFNR then
                vim.api.nvim_buf_delete(DIFF_BUFNR, { force = true })
                DIFF_BUFNR = nil
                DIFF_CHANNEL_ID = nil
            end
            CURRENT_DIFF_FILE = nil
        end,
        group = vim.api.nvim_create_augroup("EverCommitDetailsCloseAutoDiff", { clear = true }),
    })
end

---@param commit string
---@param is_stash? boolean
function M.render(commit, is_stash)
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, bufnr)
    M.set_lines(bufnr, commit)
    vim.api.nvim_set_option_value("filetype", "git", { buf = bufnr })
    set_autocmds(bufnr, commit, is_stash)
    set_keymaps(bufnr, commit, is_stash)
end

function M.cleanup(bufnr)
    require("ever._core.register").deregister_buffer(bufnr)
    if DIFF_BUFNR and vim.api.nvim_buf_is_valid(DIFF_BUFNR) then
        vim.api.nvim_buf_delete(DIFF_BUFNR, { force = true })
        DIFF_BUFNR = nil
        DIFF_CHANNEL_ID = nil
    end
    CURRENT_DIFF_FILE = nil
    vim.api.nvim_clear_autocmds({ buffer = bufnr, group = "EverCommitDetailsAutoDiff" })
    vim.api.nvim_clear_autocmds({ buffer = bufnr, group = "EverCommitDetailsCloseAutoDiff" })
end

return M
