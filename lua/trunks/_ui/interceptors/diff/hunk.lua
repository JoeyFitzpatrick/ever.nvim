---@class trunks.Hunk
---@field filename string
---@field hunk_start integer
---@field hunk_end integer
---@field patch_lines string[]
---@field patch_selected_lines? string[]

local M = {}

---@param line string
---@return boolean
local function is_patch_line(line)
    return line:sub(1, 2) == "@@"
end

---@param char string
---@return "add" | "remove" | "unchanged"
local function get_line_type(char)
    if char == "-" then
        return "remove"
    elseif char == "+" then
        return "add"
    else
        return "unchanged"
    end
end

--- Update the patch line for a range of lines
--- For adding lines, remove any lines that start with +, and remove the starting - from any lines
---@param patch_line string
---@param line_nums integer[]
---@param is_staged boolean
---@return string?
M._get_patch_line = function(patch_line, line_nums, is_staged)
    local first, last = line_nums[1], line_nums[2]
    local lines_to_apply = vim.api.nvim_buf_get_lines(0, first, last, false)
    local old_start, old_count, new_start, new_count, context =
        patch_line:match("@@ %-(%d+),(%d+) %+(%d+),(%d+) @@(.*)$")
    if not old_start or not old_count or not new_start or not new_count then
        return nil
    end
    local updated_count
    if is_staged then
        updated_count = tonumber(new_count)
    else
        updated_count = tonumber(old_count)
    end

    for _, line in ipairs(lines_to_apply) do
        local line_type = get_line_type(line:sub(1, 1))
        if line_type == "add" and not is_staged then
            updated_count = updated_count + 1
        elseif line_type == "add" and is_staged then
            updated_count = updated_count - 1
        elseif line_type == "remove" and not is_staged then
            updated_count = updated_count - 1
        elseif line_type == "remove" and is_staged then
            updated_count = updated_count + 1
        end
    end

    -- We want the old start to be the old start and new start for this patch
    if is_staged then
        local new_patch_line =
            string.format("@@ -%d,%d +%d,%d @@%s", old_start, updated_count, old_start, new_count, context)
        return new_patch_line
    end
    local new_patch_line =
        string.format("@@ -%d,%d +%d,%d @@%s", old_start, old_count, old_start, updated_count, context)
    return new_patch_line
end

---@param lines string[]
---@param patched_line_nums integer[]
---@param is_staged boolean
M._filter_patch_lines = function(lines, patched_line_nums, is_staged)
    local new_lines = {}
    for i, line in ipairs(lines) do
        if i >= patched_line_nums[1] and i <= patched_line_nums[2] then
            table.insert(new_lines, line)
        else
            local line_type = get_line_type(line:sub(1, 1))
            if line_type == "unchanged" then
                table.insert(new_lines, line)
                -- If working on staged file,
                -- remove "-" lines, and turn "+" lines into " " lines
                -- otherwise, remove "+" lines, and turn "-" lines into " " lines
            elseif line_type == "add" and is_staged then
                table.insert(new_lines, " " .. line:sub(2))
            elseif line_type == "remove" and not is_staged then
                table.insert(new_lines, " " .. line:sub(2))
            end
        end
    end
    return new_lines
end

--- This is needed for a patch to be valid according to git
---@param lines string[]
local function add_empty_line_for_patch(lines)
    table.insert(lines, "")
end

---@param line_1 string
---@param line_2 string
---@param line_3 string
---@returns string, string
local function get_patch_filenames(line_1, line_2, line_3)
    local file_before, file_after = line_1, line_2
    if line_1:match("^index") then
        file_before = line_2
        file_after = line_3
    end
    if file_before == "--- /dev/null" then
        file_before = "--- a" .. file_after:sub(6)
    elseif file_after == "+++ /dev/null" then
        file_after = "+++ b" .. file_before:sub(6)
    end
    return file_before, file_after
end

--- Returns info on a diff hunk
---@param is_staged? boolean
---@return trunks.Hunk | nil
M.extract = function(is_staged)
    local line_num = vim.api.nvim_win_get_cursor(0)[1]
    local hunk_start, hunk_end, hunk_first_changed_line = nil, nil, nil
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    for i = line_num, 1, -1 do
        if is_patch_line(lines[i]) then
            hunk_start = i + 1
            break
        end
    end
    if hunk_start == nil then
        return nil
    end

    for i = line_num + 1, #lines, 1 do
        if is_patch_line(lines[i]) then
            hunk_end = i - 1
            break
        end
    end
    if hunk_end == nil then
        hunk_end = #lines
    end

    for i = hunk_start, hunk_end, 1 do
        local line_type = get_line_type(lines[i]:sub(1, 1))
        if line_type ~= "unchanged" then
            hunk_first_changed_line = i
            break
        end
    end
    if hunk_first_changed_line == nil then
        return nil
    end

    -- First few lines of diff are like this:
    -- diff --git a/lua/trunks/keymaps/diff-keymaps.lua b/lua/trunks/keymaps/diff-keymaps.lua
    -- index 3dcb93a..8da090a 100644
    -- --- a/lua/trunks/keymaps/diff-keymaps.lua
    -- +++ b/lua/trunks/keymaps/diff-keymaps.lua
    -- @@ -9,7 +9,7 @@ M.set_unstaged_diff_keymaps = function(bufnr)

    local file_before, file_after = get_patch_filenames(lines[3], lines[4], lines[5])
    local patch_lines = { file_before, file_after }

    for i = hunk_start - 1, hunk_end do
        table.insert(patch_lines, lines[i])
    end

    add_empty_line_for_patch(patch_lines)

    local first, last = require("trunks._ui.utils.ui_utils").get_visual_line_nums()
    if is_staged == nil then
        is_staged = false
    end
    local patch_selected_lines =
        { file_before, file_after, M._get_patch_line(lines[hunk_start - 1], { first, last }, is_staged) }
    local patch_context_lines = {}
    for i = hunk_start, hunk_end do
        table.insert(patch_context_lines, lines[i])
    end
    patch_context_lines =
        M._filter_patch_lines(patch_context_lines, { first - hunk_start + 2, last - hunk_start + 1 }, is_staged)
    for _, line in ipairs(patch_context_lines) do
        table.insert(patch_selected_lines, line)
    end
    add_empty_line_for_patch(patch_selected_lines)

    return {
        filename = require("trunks._core.texter").surround_with_quotes(file_before:sub(7)),
        hunk_start = hunk_start,
        hunk_end = hunk_end,
        patch_lines = patch_lines,
        patch_selected_lines = patch_selected_lines,
    }
end

return M
