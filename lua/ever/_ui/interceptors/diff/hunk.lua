-- TODO: make all of this not complete shit
-- Really the code works, but it's completely unreadable

---@class ever.Hunk
---@field hunk_start integer
---@field hunk_end integer
---@field hunk_first_changed_line integer
---@field patch_lines string[]
---@field patch_multiple_lines? string[]
---@field next_hunk_start? integer
---@field previous_hunk_start? integer

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
---@return string?
M._get_patch = function(patch_line, line_nums)
    local first, last = line_nums[1], line_nums[2]
    local lines_to_apply = vim.api.nvim_buf_get_lines(0, first - 1, last, false)
    local old_start, old_count, new_start, new_count, context =
        patch_line:match("@@ %-(%d+),(%d+) %+(%d+),(%d+) @@(.*)$")
    if not old_start or not old_count or not new_start or not new_count then
        return nil
    end

    new_count = tonumber(old_count)

    for _, line in ipairs(lines_to_apply) do
        local line_type = get_line_type(line:sub(1, 1))
        if line_type == "add" then
            new_count = new_count + 1
        elseif line_type == "remove" then
            new_count = new_count - 1
        end
    end

    local new_patch_line = string.format("@@ -%d,%d +%d,%d @@%s", old_start, old_count, new_start, new_count, context)
    return new_patch_line
end

---@param lines string[]
---@param patched_line_num integer | integer[]
M._filter_patch_lines = function(lines, patched_line_num)
    if type(patched_line_num) == "number" then
        patched_line_num = { patched_line_num - 1, patched_line_num }
    end
    local new_lines = {}
    for i, line in ipairs(lines) do
        if i > patched_line_num[1] and i <= patched_line_num[2] then
            table.insert(new_lines, line)
        else
            local line_type = get_line_type(line:sub(1, 1))
            if line_type == "remove" then
                table.insert(new_lines, " " .. line:sub(2))
            elseif line_type == "unchanged" then
                table.insert(new_lines, line)
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

--- Returns info on a diff hunk
---@return ever.Hunk | nil
M.extract = function()
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

    local next_hunk_start, previous_hunk_start = nil, nil
    for i = hunk_start - 2, 1, -1 do -- -2 represents the line before the @@ line of the current hunk
        if is_patch_line(lines[i]) then
            previous_hunk_start = i
            break
        end
    end

    local not_in_last_line = lines[hunk_end + 1] and lines[hunk_end + 2]
    if not_in_last_line and is_patch_line(lines[hunk_end + 1]) then
        next_hunk_start = hunk_end + 1
    end

    -- First few lines of diff are like this:
    -- diff --git a/lua/alien/keymaps/diff-keymaps.lua b/lua/alien/keymaps/diff-keymaps.lua
    -- index 3dcb93a..8da090a 100644
    -- --- a/lua/alien/keymaps/diff-keymaps.lua
    -- +++ b/lua/alien/keymaps/diff-keymaps.lua
    -- @@ -9,7 +9,7 @@ M.set_unstaged_diff_keymaps = function(bufnr)

    local patch_lines = { lines[3], lines[4] }

    for i = hunk_start - 1, hunk_end do
        table.insert(patch_lines, lines[i])
    end

    add_empty_line_for_patch(patch_lines)

    local first, last = require("ever._ui.utils.ui_utils").get_visual_line_nums()
    local patch_multiple_lines = { lines[3], lines[4], M._get_patch(lines[hunk_start - 1], { first + 1, last }) }
    local patch_context_lines = {}
    for i = hunk_start, hunk_end do
        table.insert(patch_context_lines, lines[i])
    end
    patch_context_lines = M._filter_patch_lines(patch_context_lines, { first - hunk_start + 1, last - hunk_start + 1 })
    for _, line in ipairs(patch_context_lines) do
        table.insert(patch_multiple_lines, line)
    end
    add_empty_line_for_patch(patch_multiple_lines)

    return {
        hunk_start = hunk_start,
        hunk_end = hunk_end,
        hunk_first_changed_line = hunk_first_changed_line,
        patch_lines = patch_lines,
        patch_multiple_lines = patch_multiple_lines,
        next_hunk_start = next_hunk_start,
        previous_hunk_start = previous_hunk_start,
    }
end

return M
