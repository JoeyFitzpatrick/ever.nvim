---@class ever.DiffLineData
---@field filename string
---@field safe_filename string

local M = {}

local DIFF_BUFNR = nil
local CURRENT_DIFF_FILE = nil
---@type string
local COMMITS_TO_DIFF = ""

---@param cmd string
---@return string
function M._get_commits_to_diff(cmd)
    local commits = ""
    local cmd_args = vim.tbl_filter(function(cmd_arg)
        return cmd_arg:sub(1, 1) ~= "-"
    end, vim.split(cmd, " "))
    if #cmd_args >= 2 then
        commits = cmd_args[2]
    end
    if commits ~= "" and not commits:match("%.%.") then
        commits = "HEAD.." .. commits
    end
    return commits
end

--- This sets COMMITS_TO_DIFF, which is used to derive commands to see what files to diff and create diff commands.
local function set_commits_to_diff(cmd)
    COMMITS_TO_DIFF = M._get_commits_to_diff(cmd)
end

---@return string[]
local function get_diff_files()
    local diff_cmd = string.format("git diff --name-status %s", COMMITS_TO_DIFF)
    local diff_stat_cmd = diff_cmd:gsub("%-%-name%-status", "--numstat", 1)
    local diff_files = require("ever._core.run_cmd").run_cmd(diff_cmd)
    local diff_stats = require("ever._core.run_cmd").run_cmd(diff_stat_cmd)
    if #diff_files ~= #diff_stats then
        error("Unable to parse diff stats")
    end
    local diff_files_with_stats = {}
    for i = 1, #diff_files do
        local file_with_status = diff_files[i]
        local diff_stat = diff_stats[i]
        local status = file_with_status:sub(1, 1)
        local filename = file_with_status:match("%S+$")
        local lines_added = diff_stat:match("%S+")
        local lines_removed = diff_stat:match("%s(%S+)")
        table.insert(diff_files_with_stats, string.format("%s %s %d, %d", status, filename, lines_added, lines_removed))
    end
    return diff_files_with_stats
end

--- Highlight difftool lines
---@param bufnr integer
local function highlight(bufnr)
    local highlight_line = require("ever._ui.highlight").highlight_line
    for i, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
        local line_num = i - 1
        local status_start, status_end = 1, 2
        highlight_line(bufnr, "Keyword", line_num, status_start, status_end)
        local lines_added_start, lines_added_end = line:find("(%d+),", status_end + 1)
        highlight_line(bufnr, "Added", line_num, lines_added_start, lines_added_end)
        if not lines_added_end then
            return
        end
        local lines_removed_start, lines_removed_end = line:find("%d+", lines_added_end + 1)
        highlight_line(bufnr, "Removed", line_num, lines_removed_start, lines_removed_end)
    end
end

---@param bufnr integer
---@param line_num? integer
---@return ever.DiffLineData | nil
local function get_line(bufnr, line_num)
    line_num = line_num or vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1]
    if line == "" then
        return nil
    end
    local filename = line:match("%S+", 3)
    return { filename = filename, safe_filename = "'" .. filename .. "'" }
end

--- Uses COMMITS_TO_DIFF to create a command to diff a file between commits
---@param filename string
---@return string
local function get_diff_cmd(filename)
    return string.format("git diff %s -- %s", COMMITS_TO_DIFF, filename)
end

local function set_diff_buffer_autocmds(diff_bufnr)
    vim.api.nvim_create_autocmd("BufHidden", {
        desc = "Clean up autodiff variables and buffer",
        buffer = diff_bufnr,
        callback = function()
            DIFF_BUFNR = nil
            CURRENT_DIFF_FILE = nil
        end,
    })
end

---@param bufnr integer The bufnr of the buffer that shows the diff
local function set_diff_buffer_keymaps(bufnr)
    require("ever._ui.interceptors.diff.diff_keymaps").set_keymaps(bufnr)
    local keymaps = require("ever._ui.keymaps.base").get_keymaps(bufnr, "diff", {})
    local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }
    local set = require("ever._ui.keymaps.set").safe_set_keymap

    set("n", "q", function()
        local upper_win = vim.fn.winnr("k")
        if upper_win == 0 then
            return
        end
        local win = vim.fn.win_getid(upper_win)
        vim.api.nvim_set_current_win(win)
        vim.api.nvim_buf_delete(0, { force = true })
    end, keymap_opts)

    set("n", keymaps.next_file, function()
        local upper_win = vim.fn.winnr("k")
        if upper_win == 0 then
            return
        end
        local win = vim.fn.win_getid(upper_win)
        vim.api.nvim_set_current_win(win)
        local cursor_pos = vim.api.nvim_win_get_cursor(win)
        vim.api.nvim_win_set_cursor(win, { cursor_pos[1] + 1, cursor_pos[2] })
        vim.schedule(function()
            local lower_win = vim.fn.win_getid(vim.fn.winnr("j"))
            vim.api.nvim_set_current_win(lower_win)
        end)
    end, keymap_opts)

    set("n", keymaps.previous_file, function()
        local upper_win = vim.fn.winnr("k")
        if upper_win == 0 then
            return
        end
        local win = vim.fn.win_getid(upper_win)
        vim.api.nvim_set_current_win(win)
        local cursor_pos = vim.api.nvim_win_get_cursor(win)
        vim.api.nvim_win_set_cursor(win, { cursor_pos[1] - 1, cursor_pos[2] })
        vim.schedule(function()
            local lower_win = vim.fn.win_getid(vim.fn.winnr("j"))
            vim.api.nvim_set_current_win(lower_win)
        end)
    end, keymap_opts)
end

---@param bufnr integer The bufnr of the buffer that shows the diff
---@param line_data ever.DiffLineData Line data
local function setup_diff_buffer(bufnr, line_data)
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end
    local cmd = get_diff_cmd(line_data.safe_filename)
    require("ever._core.register").register_buffer(bufnr, {
        render_fn = function()
            require("ever._ui.stream").stream_lines(bufnr, cmd, {})
        end,
    })
    require("ever._ui.stream").stream_lines(bufnr, cmd, {})
    set_diff_buffer_autocmds(bufnr)
    set_diff_buffer_keymaps(bufnr)
end

---@param bufnr integer
local function set_autocmds(bufnr)
    vim.api.nvim_create_autocmd("CursorMoved", {
        desc = "Diff the file under the cursor",
        buffer = bufnr,
        callback = function()
            local line_data = get_line(bufnr)
            if not line_data or line_data.filename == CURRENT_DIFF_FILE then
                return
            end
            CURRENT_DIFF_FILE = line_data.filename
            if DIFF_BUFNR and vim.api.nvim_buf_is_valid(DIFF_BUFNR) then
                vim.api.nvim_buf_delete(DIFF_BUFNR, { force = true })
            end
            DIFF_BUFNR = vim.api.nvim_create_buf(false, true)
            DIFF_BUFNR = require("ever._ui.elements").new_buffer({
                filetype = "git",
                buffer_name = "EverDiff--" .. line_data.filename,
                enter = false,
                win_config = { split = "below", height = math.floor(vim.o.lines * 0.67) },
            })
            setup_diff_buffer(DIFF_BUFNR, line_data)
        end,
        group = vim.api.nvim_create_augroup("EverDiffAutoDiff", { clear = true }),
    })

    vim.api.nvim_create_autocmd({ "BufWipeout" }, {
        desc = "Close open diffs when buffer is hidden",
        buffer = bufnr,
        callback = function()
            if DIFF_BUFNR and vim.api.nvim_buf_is_valid(DIFF_BUFNR) then
                vim.api.nvim_buf_delete(DIFF_BUFNR, { force = true })
                DIFF_BUFNR = nil
            end
            CURRENT_DIFF_FILE = nil
        end,
        group = vim.api.nvim_create_augroup("EverDiffCloseAutoDiff", { clear = true }),
    })
end

local function set_keymaps(bufnr)
    local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }

    vim.keymap.set("n", "q", function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end, keymap_opts)
end

---@param cmd string
M.render = function(cmd)
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, bufnr)
    set_commits_to_diff(cmd)
    vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, get_diff_files())
    highlight(bufnr)
    vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
    set_keymaps(bufnr)
    set_autocmds(bufnr)
end

function M.cleanup(bufnr)
    if DIFF_BUFNR then
        vim.api.nvim_buf_delete(DIFF_BUFNR, { force = true })
        DIFF_BUFNR = nil
    end
    CURRENT_DIFF_FILE = nil
    vim.api.nvim_clear_autocmds({ buffer = bufnr, group = "EverDiffAutoDiff" })
    vim.api.nvim_clear_autocmds({ buffer = bufnr, group = "EverDiffCloseAutoDiff" })
end

return M
