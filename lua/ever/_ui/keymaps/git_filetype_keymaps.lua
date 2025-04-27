---@alias ever.GitFiletypeOutputType "commit" | "filepath" | "previous_filepath" | "vimdiff"

---@class ever.GitFiletypeLineData
---@field item_type ever.GitFiletypeOutputType
---@field commit? string
---@field previous_commit? string
---@field filepath? string
---@field previous_filepath? string

local PREVIOUS_FILE_PATTERN = "^%-%-%-%s%l"
local CURRENT_FILE_PATTERN = "^%+%+%+%s%l"
local DIFF_PATTERN = "^diff"
local HUNK_START_PATTERN = "^@@"

local M = {}

---@return ever.GitFiletypeOutputType
local function get_item_type()
    local current_line = vim.api.nvim_get_current_line()
    if current_line:match(PREVIOUS_FILE_PATTERN) then
        return "previous_filepath"
    elseif current_line:match(CURRENT_FILE_PATTERN) then
        return "filepath"
    elseif current_line:match(DIFF_PATTERN) or current_line:match(HUNK_START_PATTERN) then
        return "vimdiff"
    else
        return "commit"
    end
end

--- Search backwards from cursor position to find commit
---@param bufnr integer
---@param cursor_row integer
---@return string | nil
local function find_commit(bufnr, cursor_row)
    while cursor_row > 0 do
        local line = vim.api.nvim_buf_get_lines(bufnr, cursor_row - 1, cursor_row, false)[1]
        if line:match("^commit") then
            return line:match("%x+", 8)
        end
        cursor_row = cursor_row - 1
    end
    return nil
end

---@param commit string
---@return string
local function get_previous_commit(commit)
    local previous_commit_hash_output =
        require("ever._core.run_cmd").run_cmd("git rev-list --parents -n 1 " .. commit)[1]
    local previous_commit = previous_commit_hash_output:match("%s(%x+)")
    if not previous_commit then
        -- if we can't parse the hash, just use commit + ^
        previous_commit = commit .. "^"
    end
    return previous_commit
end

---@param line string
---@return string
local function parse_filepath(line)
    return line:match("%S+", 7)
end

---@param bufnr integer
---@return ever.GitFiletypeLineData | nil
local function get_line(bufnr)
    local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
    local output = {}
    output.item_type = get_item_type()
    output.commit = find_commit(bufnr, cursor_row)

    if not output.commit then
        return nil
    end

    if output.item_type == "commit" then
        return output
    end

    output.previous_commit = get_previous_commit(output.commit)

    local current_line = vim.api.nvim_get_current_line()
    if current_line:match(PREVIOUS_FILE_PATTERN) then
        output.previous_filepath = parse_filepath(current_line)
        output.filepath = parse_filepath(vim.api.nvim_buf_get_lines(bufnr, cursor_row, cursor_row + 1, false)[1])
    elseif current_line:match(CURRENT_FILE_PATTERN) then
        output.filepath = parse_filepath(current_line)
        output.previous_filepath =
            parse_filepath(vim.api.nvim_buf_get_lines(bufnr, cursor_row - 1, cursor_row, false)[1])
    elseif current_line:match(DIFF_PATTERN) then
        local filepath_line_num = cursor_row
        local next_line = vim.api.nvim_buf_get_lines(bufnr, cursor_row, cursor_row + 1, false)[1]
        local next_line_is_filepath = next_line ~= nil and next_line:match("%-%-%-")

        -- In some cases, the lines after "^diff" are the filepaths, but in some cases,
        -- there is an "^index" line first. If there is the index line, skip it.
        if not next_line_is_filepath then
            filepath_line_num = filepath_line_num + 1
        end

        output.previous_filepath =
            parse_filepath(vim.api.nvim_buf_get_lines(bufnr, filepath_line_num, filepath_line_num + 1, false)[1])
        output.filepath =
            parse_filepath(vim.api.nvim_buf_get_lines(bufnr, filepath_line_num + 1, filepath_line_num + 2, false)[1])
    elseif current_line:match(HUNK_START_PATTERN) then
        output.previous_filepath =
            parse_filepath(vim.api.nvim_buf_get_lines(bufnr, cursor_row - 3, cursor_row - 2, false)[1])
        output.filepath = parse_filepath(vim.api.nvim_buf_get_lines(bufnr, cursor_row - 2, cursor_row - 1, false)[1])
    end

    return output
end

---@param line_data ever.GitFiletypeLineData | nil
---@param open_type "tab" | "window" | "vertical" | "horizontal"
---@return { file_to_open: string, commit_to_use: string } | nil
local function open_file(line_data, open_type)
    if not line_data then
        return nil
    end

    local file_to_open, commit_to_use = nil, nil
    if line_data.item_type == "filepath" then
        file_to_open = line_data.filepath
        commit_to_use = line_data.commit
    elseif line_data.item_type == "previous_filepath" then
        file_to_open = line_data.previous_filepath
        commit_to_use = line_data.previous_commit
    end
    if not file_to_open or not commit_to_use then
        return nil
    end

    if open_type == "tab" then
        require("ever._core.open_file").open_file_in_tab(file_to_open, commit_to_use)
    elseif open_type == "window" then
        require("ever._core.open_file").open_file_in_current_window(file_to_open, commit_to_use)
    elseif open_type == "vertical" then
        require("ever._core.open_file").open_file_in_split(file_to_open, commit_to_use, "right")
    elseif open_type == "horizontal" then
        require("ever._core.open_file").open_file_in_split(file_to_open, commit_to_use, "below")
    end
end

---@param bufnr integer
function M.set_keymaps(bufnr)
    require("ever._ui.interceptors.diff.diff_keymaps").set_keymaps(bufnr)
    local keymaps = require("ever._ui.keymaps.base").get_keymaps(
        bufnr,
        "git_filetype",
        { open_file_keymaps = true, diff_keymaps = true }
    )
    local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }
    local set = require("ever._ui.keymaps.set").safe_set_keymap

    set("n", keymaps.show_details, function()
        local line_data = get_line(bufnr)
        if not line_data or not line_data.commit then
            return
        end
        local item_type = line_data.item_type
        if item_type == "commit" then
            require("ever._ui.commit_details").render(line_data.commit, false)
        elseif item_type == "filepath" then
            require("ever._core.open_file").open_file_in_split(line_data.filepath, line_data.commit, "right")
        elseif item_type == "previous_filepath" then
            require("ever._core.open_file").open_file_in_split(
                line_data.previous_filepath,
                line_data.previous_commit,
                "right"
            )
        elseif item_type == "vimdiff" then
            require("ever._core.open_file").open_file_in_split(
                line_data.previous_filepath,
                line_data.previous_commit,
                "below"
            )
            vim.cmd("diffthis")
            require("ever._core.open_file").open_file_in_split(line_data.filepath, line_data.commit, "right")
            vim.cmd("diffthis")
        end
    end, keymap_opts)

    set("n", keymaps.open_in_current_window, function()
        open_file(get_line(bufnr), "window")
    end, keymap_opts)

    set("n", keymaps.open_in_horizontal_split, function()
        open_file(get_line(bufnr), "horizontal")
    end, keymap_opts)

    set("n", keymaps.open_in_new_tab, function()
        open_file(get_line(bufnr), "tab")
    end, keymap_opts)

    set("n", keymaps.open_in_vertical_split, function()
        open_file(get_line(bufnr), "vertical")
    end, keymap_opts)
end

return M
