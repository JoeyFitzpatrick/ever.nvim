---@class ever.Hunk
---@field hunk_start integer
---@field hunk_end integer
---@field hunk_first_changed_line integer
---@field patch_lines string[]
---@field patch_single_line? string[]
---@field next_hunk_start? integer
---@field previous_hunk_start? integer

local M = {}

---@param line string
---@return boolean
local function is_patch_line(line)
    return line:sub(1, 2) == "@@"
end

--- Whatever the current patch is, just add one line
--- For adding a line, remove any lines that start with +, and remove the starting - from any lines
---@param patch_line string
---@param line_to_apply string
---@return string?
M._get_single_line_patch = function(patch_line, line_to_apply)
    local old_num_lines = patch_line:match(",(%d+)")
    local new_num_lines
    local first_char = line_to_apply:sub(1, 1)
    if first_char == "+" then
        new_num_lines = tonumber(old_num_lines) + 1
    elseif first_char == "-" then
        new_num_lines = tonumber(old_num_lines) - 1
    else
        return nil
    end
    local new_patch_line = patch_line:gsub("(%+%d+,)%d+", "%1" .. tostring(new_num_lines), 1)
    return new_patch_line
end

---@param lines string[]
---@param patched_line_num integer
M._filter_patch_lines = function(lines, patched_line_num)
    local new_lines = {}
    for i, line in ipairs(lines) do
        if i == patched_line_num then
            table.insert(new_lines, line)
            goto continue
        end
        local first_char = line:sub(1, 1)
        if first_char == "+" then
            goto continue
        elseif first_char == "-" then
            table.insert(new_lines, " " .. line:sub(2))
        else
            table.insert(new_lines, line)
        end
        ::continue::
    end
    return new_lines
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
        local first_char = lines[i]:sub(1, 1)
        if first_char == "+" or first_char == "-" then
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
            previous_hunk_start = i + 1
            break
        end
    end

    local not_in_last_line = lines[hunk_end + 1] and lines[hunk_end + 2]
    if not_in_last_line and is_patch_line(lines[hunk_end + 1]) then
        next_hunk_start = hunk_end + 2
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

    -- TODO: figure out why this is needed to make applying patches not fail due to corrupt patch errors
    table.insert(patch_lines, "")

    local patch_single_line = nil
    local current_line = lines[line_num]
    if not is_patch_line(current_line) then
        patch_single_line = {
            lines[3],
            lines[4],
            M._get_single_line_patch(lines[hunk_start - 1], current_line),
        }
        local patch_context_lines = {}
        for i = hunk_start, hunk_end do
            table.insert(patch_context_lines, lines[i])
        end
        patch_context_lines = M._filter_patch_lines(patch_context_lines, line_num - (hunk_start - 1))
        for _, line in ipairs(patch_context_lines) do
            table.insert(patch_single_line, line)
        end
        table.insert(patch_single_line, "")
    end

    return {
        hunk_start = hunk_start,
        hunk_end = hunk_end,
        hunk_first_changed_line = hunk_first_changed_line,
        patch_lines = patch_lines,
        patch_single_line = patch_single_line,
        next_hunk_start = next_hunk_start,
        previous_hunk_start = previous_hunk_start,
    }
end

return M
