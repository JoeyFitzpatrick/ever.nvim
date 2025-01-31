local M = {}

--- Get diff stats for a group of files.
--- Each file should be formatted something like `status` `filename` `number of changed files`
---@param commit1 string
---@param commit2 string
---@return string[]
M.get_diff_stats = function(commit1, commit2)
    local raw_diff_stats = M._get_raw_diff_stats(commit1, commit2)
    local files_with_status = raw_diff_stats.files_with_status
    local files_with_changed_lines = raw_diff_stats.files_with_changed_lines
    if #files_with_status ~= #files_with_changed_lines then
        error("Alien: unable to parse diff stats")
    end
    local diff_stats = {}
    for i = 1, #files_with_status do
        local file_with_status = files_with_status[i]
        local file_with_changed_lines = files_with_changed_lines[i]
        local status = file_with_status:sub(1, 1)
        local filename = file_with_status:match("%S+$")
        local lines_added = file_with_changed_lines:match("%S+")
        local lines_removed = file_with_changed_lines:match("%s(%S+)")
        table.insert(diff_stats, string.format("%s %s %d, %d", status, filename, lines_added, lines_removed))
    end
    return diff_stats
end

-- TODO: remove flags and such so that this just looks at the commits
---@param cmd string
---@return string[]
local function get_diff_files(cmd)
    vim.print(cmd)
    local cmd_args = vim.split(cmd, " ")
    local diff_cmd
    if #cmd_args >= 3 then
        diff_cmd = string.format("git diff --name-status %s %s", cmd_args[2], cmd_args[3])
    elseif #cmd_args == 2 then
        diff_cmd = string.format("git diff --name-status %s", cmd_args[2])
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

---@param cmd string
M.render = function(cmd)
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, bufnr)
    local diff_files = get_diff_files(cmd)
    vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, diff_files)
    vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
    highlight(bufnr)

    vim.keymap.set("n", "q", function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end, { buffer = bufnr })
end

return M
