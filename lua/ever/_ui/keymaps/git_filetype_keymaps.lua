---@class ever.GitFiletypeLineData
---@field item_type "commit" | "filepath"
---@field commit? string
---@field filepath? string

local M = {}

---@param bufnr integer
---@param cursor_row integer
---@return string | nil
local function find_commit_from_cursor(bufnr, cursor_row)
    while cursor_row > 1 do
        local line = vim.api.nvim_buf_get_lines(bufnr, cursor_row - 2, cursor_row - 1, false)[1]
        if line:match("^commit") then
            return line:match("%x+", 8)
        end
        cursor_row = cursor_row - 1
    end
    return nil
end

---@param bufnr
---@return ever.GitFiletypeLineData | nil
local function get_line(bufnr)
    local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_buf_get_lines(bufnr, cursor_row - 1, cursor_row, false)[1]

    if line:match("^commit") then
        return { commit = line:match("%x+", 8), item_type = "commit" }
    end

    if line:match("^%-%-%-%s%l") then
        local ok, commit = pcall(find_commit_from_cursor, bufnr, cursor_row)
        if not ok or not commit then
            return nil
        end
        -- return file with previous commit
        local previous_commit_hash_output =
            require("ever._core.run_cmd").run_cmd("git rev-list --parents -n 1 " .. commit)[1]
        local previous_commit_hash = previous_commit_hash_output:match("%s(%x+)")
        if not previous_commit_hash then
            -- if we can't parse the hash, just use commit + ^
            commit = commit .. "^"
        else
            commit = previous_commit_hash
        end
        return { commit = commit, filepath = line:match("%S+", 7), item_type = "filepath" }
    end

    if line:match("^%+%+%+%s%l") then
        local ok, commit = pcall(find_commit_from_cursor, bufnr, cursor_row)
        if not ok then
            return nil
        end
        return { commit = commit, filepath = line:match("%S+", 7), item_type = "filepath" }
    end

    return nil
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
