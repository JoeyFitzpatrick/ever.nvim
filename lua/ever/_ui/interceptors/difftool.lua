---@class ever.DiffLineData
---@field filename string
---@field safe_filename string

local M = {}

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

---@param commits_to_diff string
---@return string[]
local function get_diff_files(commits_to_diff)
    local diff_cmd = string.format("git diff --name-status %s", commits_to_diff)
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
    local commits_to_diff = M._get_commits_to_diff(cmd)
    vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, get_diff_files(commits_to_diff))
    highlight(bufnr)
    vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
    set_keymaps(bufnr)
    require("ever._ui.auto_display").create_auto_display(bufnr, "difftool", {
        generate_cmd = function()
            local line_data = get_line(bufnr)
            if not line_data then
                return
            end
            return string.format("diff %s -- %s", commits_to_diff, line_data.safe_filename)
        end,
        get_current_diff = function()
            local line_data = get_line(bufnr)
            if not line_data then
                return
            end
            return line_data.safe_filename
        end,
        strategy = { display_strategy = "below", win_size = 0.67 },
    })
end

return M
