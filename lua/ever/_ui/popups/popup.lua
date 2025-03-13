---@class ever.RenderPopupOpts
---@field ui_type string
---@field title string
---@field buffer_name string

local M = {}

---@param ui_type string
---@param title string
---@return string[]
local function get_popup_lines(ui_type, title)
    local mappings = require("ever._core.configuration").DATA[ui_type].keymaps
    local descriptions = require("ever._constants.keymap_descriptions")[ui_type]
    local lines = { " " .. title }
    for command, keys in pairs(mappings) do
        table.insert(lines, string.format(" %s %s\t", keys, descriptions[command]))
    end
    return lines
end

local function highlight(bufnr)
    require("ever._ui.highlight").highlight_line(bufnr, "Function", 0, 1, -1)
    -- We highlight the first line differently, so skip the first line in this loop
    for i, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 1, -1, false)) do
        local keys_start, keys_end = line:find("%s?%w+%s")
        require("ever._ui.highlight").highlight_line(bufnr, "Keyword", i, keys_start, keys_end)
    end
end

local function set_popup_settings()
    vim.opt.number = false
    vim.opt.relativenumber = false
end

---@param opts ever.RenderPopupOpts
function M.render_popup(opts)
    local bufnr = require("ever._ui.elements").new_buffer({
        buffer_name = opts.buffer_name,
        win_config = { split = "below" },
        lines = function()
            return get_popup_lines(opts.ui_type, opts.title)
        end,
    })
    set_popup_settings()
    highlight(bufnr)
    return bufnr
end

return M
