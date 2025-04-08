---@class ever.GitFiletypeLineData
---@field item_type "commit" | "filepath" | "previous_filepath"
---@field commit? string
---@field previous_commit? string
---@field filepath? string
---@field previous_filepath? string

local PREVIOUS_FILE_PATTERN = "^%-%-%-%s%l"
local CURRENT_FILE_PATTERN = "^%+%+%+%s%l"

local M = {}

---@return string
local function get_item_type()
    local current_line = vim.api.nvim_get_current_line()
    if current_line:match(PREVIOUS_FILE_PATTERN) then
        return "previous_filepath"
    elseif current_line:match(CURRENT_FILE_PATTERN) then
        return "filepath"
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
    end

    return output
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
        end
    end, keymap_opts)

    set("n", keymaps.open_in_current_window, function()
        local line_data = get_line(bufnr)
        if not line_data or line_data.item_type ~= "filepath" then
            return
        end
        require("ever._core.open_file").open_file_in_current_window(line_data.filepath, line_data.commit)
    end, keymap_opts)

    set("n", keymaps.open_in_horizontal_split, function()
        local line_data = get_line(bufnr)
        if not line_data or line_data.item_type ~= "filepath" then
            return
        end
        require("ever._core.open_file").open_file_in_split(line_data.filepath, line_data.commit, "below")
    end, keymap_opts)

    set("n", keymaps.open_in_new_tab, function()
        local line_data = get_line(bufnr)
        if not line_data or line_data.item_type ~= "filepath" then
            return
        end
        require("ever._core.open_file").open_file_in_tab(line_data.filepath, line_data.commit)
    end, keymap_opts)

    set("n", keymaps.open_in_vertical_split, function()
        local line_data = get_line(bufnr)
        if not line_data or line_data.item_type ~= "filepath" then
            return
        end
        require("ever._ui.auto_display").close_auto_display(bufnr, "commit_details")
        require("ever._core.open_file").open_file_in_split(line_data.filepath, line_data.commit, "right")
    end, keymap_opts)
end

return M
