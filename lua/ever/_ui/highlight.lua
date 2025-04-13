local M = {}

local function hex_to_rgb(hex)
    local r = tonumber(hex:sub(2, 3), 16)
    local g = tonumber(hex:sub(4, 5), 16)
    local b = tonumber(hex:sub(6, 7), 16)
    return r, g, b
end

local function rgb_to_hex(r, g, b)
    return string.format("#%02X%02X%02X", r, g, b)
end

local function modify_color(hex, modification_level)
    local r, g, b = hex_to_rgb(hex)
    r = math.floor(r * modification_level)
    g = math.floor(g * modification_level)
    b = math.floor(b * modification_level)
    return rgb_to_hex(r, g, b):sub(1, 7)
end

--- convert a commit hash to a hex color to color the hash
---@param hash string
function M.commit_hash_to_hex(hash)
    local stripped_hash = hash:gsub("%d", "")
    if #hash < 6 then
        return { hex = "", stripped_hash = stripped_hash }
    end
    local hex = "#" .. hash:sub(1, 6)
    return { hex = modify_color(hex, 0.85), stripped_hash = stripped_hash }
end

--- Make highlighting a line a little easier.
---@param bufnr integer
---@param highlight_group string
---@param line_num integer
---@param start? integer
---@param finish? integer
function M.highlight_line(bufnr, highlight_group, line_num, start, finish)
    if start and finish then
        vim.hl.range(
            bufnr,
            vim.api.nvim_create_namespace(""),
            highlight_group,
            { line_num, start - 1 },
            { line_num, finish }
        )
    end
end

return M
