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
    return commits
end

--- This sets COMMITS_TO_DIFF, which is used to derive commands to see what files to diff and create diff commands.
local function set_commits_to_diff(cmd)
    COMMITS_TO_DIFF = M._get_commits_to_diff(cmd)
end

---@return string[]
local function get_diff_files()
    local diff_cmd
    if COMMITS_TO_DIFF ~= "" then
        diff_cmd = string.format("git diff --name-status %s", COMMITS_TO_DIFF)
    else
        diff_cmd = "git diff --name-status"
    end
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

--- Highlight stash lines
---@param bufnr integer
local function highlight(bufnr)
    local highlight_line = require("ever._ui.highlight").highlight_line
    for i, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
        local line_num = i - 1
        local status_start, status_end = 1, 2
        highlight_line(bufnr, "Keyword", line_num, status_start, status_end)
        local lines_added_start, lines_added_end = line:find("(%d+),", status_end + 1)
        highlight_line(bufnr, "Added", line_num, lines_added_start, lines_added_end)
        local lines_removed_start, lines_removed_end = line:find("%d+", lines_added_end + 1)
        highlight_line(bufnr, "Removed", line_num, lines_removed_start, lines_removed_end)
    end
end

---@param bufnr integer
---@param line_num? integer
---@return { filename: string, safe_filename: string } | nil
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
    local diff_cmd
    if COMMITS_TO_DIFF ~= "" then
        diff_cmd = string.format("git diff %s -- %s", COMMITS_TO_DIFF, filename)
    else
        diff_cmd = "git diff " .. filename
    end
    return diff_cmd
end

local function set_diff_buffer_autocmds(diff_bufnr)
    vim.api.nvim_create_autocmd("BufHidden", {
        desc = "Clean up diff variables",
        buffer = diff_bufnr,
        callback = function()
            DIFF_BUFNR = nil
            CURRENT_DIFF_FILE = nil
        end,
    })
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
                DIFF_BUFNR = nil
            end
            DIFF_BUFNR = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_open_win(DIFF_BUFNR, false, { split = "below", height = math.floor(vim.o.lines * 0.67) })
            local diff_lines = require("ever._core.run_cmd").run_cmd(get_diff_cmd(line_data.safe_filename))
            vim.api.nvim_set_option_value("filetype", "git", { buf = DIFF_BUFNR })
            vim.api.nvim_buf_set_lines(DIFF_BUFNR, 0, -1, false, diff_lines)
            vim.api.nvim_set_option_value("modifiable", false, { buf = DIFF_BUFNR })
            set_diff_buffer_autocmds(DIFF_BUFNR)
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
    local diff_files = get_diff_files()
    vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, diff_files)
    vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
    highlight(bufnr)
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
