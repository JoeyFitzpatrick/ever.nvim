-- Commit details

---@class ever.CommitDetailsLineData
---@field filename string
---@field safe_filename string

local M = {}

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
local function set_keymaps(bufnr, commit)
    local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }
    local keymaps = require("ever._ui.keymaps.base").get_keymaps(
        bufnr,
        "commit_details",
        { open_file_keymaps = true, auto_display_keymaps = true }
    )
    local set = require("ever._ui.keymaps.set").safe_set_keymap

    set("n", keymaps.open_in_current_window, function()
        local ok, line_data = pcall(M.get_line, bufnr)
        if not ok or not line_data then
            return
        end
        require("ever._core.open_file").open_file_in_current_window(line_data.filename, commit)
    end, keymap_opts)

    set("n", keymaps.open_in_horizontal_split, function()
        local ok, line_data = pcall(M.get_line, bufnr)
        if not ok or not line_data then
            return
        end
        require("ever._ui.auto_display").close_auto_display(bufnr, "commit_details")
        require("ever._core.open_file").open_file_in_split(line_data.filename, commit, "below")
    end, keymap_opts)

    set("n", keymaps.open_in_new_tab, function()
        local ok, line_data = pcall(M.get_line, bufnr)
        if not ok or not line_data then
            return
        end
        require("ever._core.open_file").open_file_in_tab(line_data.filename, commit)
    end, keymap_opts)

    set("n", keymaps.open_in_vertical_split, function()
        local ok, line_data = pcall(M.get_line, bufnr)
        if not ok or not line_data then
            return
        end
        require("ever._ui.auto_display").close_auto_display(bufnr, "commit_details")
        require("ever._core.open_file").open_file_in_split(line_data.filename, commit, "right")
    end, keymap_opts)

    set("n", keymaps.show_all_changes, function()
        vim.cmd("G show " .. commit)
    end, keymap_opts)
end

---@param commit string
---@param is_stash? boolean
function M.render(commit, is_stash)
    local bufnr = require("ever._ui.elements").new_buffer({ filetype = "git" })
    M.set_lines(bufnr, commit)
    require("ever._ui.auto_display").create_auto_display(bufnr, "commit_details", {
        generate_cmd = function()
            local ok, line_data = pcall(M.get_line, bufnr)
            if not ok or not line_data then
                return
            end
            -- The -m flag diffs both merge commits and normal commits.
            -- Empty pretty format omits commit message, and everything aside from the diff itself.
            local cmd = "git show -m --pretty=format:'' " .. commit .. " -- " .. line_data.safe_filename
            if is_stash then
                cmd = string.format("git diff %s^1 %s -- %s", commit, commit, line_data.safe_filename)
            end
            return cmd
        end,
        get_current_diff = function()
            local ok, line_data = pcall(M.get_line, bufnr)
            if not ok or not line_data then
                return
            end
            return line_data.filename
        end,
        strategy = { display_strategy = "below", win_size = 0.67, insert = false, enter = false },
    })
    set_keymaps(bufnr, commit)
end

return M
