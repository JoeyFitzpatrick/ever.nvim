---@class ever.RenderPopupMapping
---@field keys string
---@field description string
---@field action string | function

---@class ever.RenderPopupOpts
---@field ui_type? string
---@field title string
---@field buffer_name string
---@field mappings? ever.RenderPopupMapping[]

local M = {}

---@param bufnr integer
---@param mapping_config string | ever.RenderPopupMapping[]
---@param title string
---@return string[]
local function get_popup_lines(bufnr, mapping_config, title)
    if type(mapping_config) == "string" then
        local ui_type = mapping_config
        local mappings = require("ever._core.configuration").DATA[ui_type].keymaps
        local descriptions = require("ever._constants.keymap_descriptions")[ui_type]
        local lines = { " " .. title }
        for command, keys in pairs(mappings) do
            table.insert(lines, string.format(" %s %s\t", keys, descriptions[command]))
        end
        return lines
    elseif type(mapping_config) == "table" then
        local lines = { " " .. title }
        for _, mapping in ipairs(mapping_config) do
            table.insert(lines, string.format(" %s %s\t", mapping.keys, mapping.description))
            require("ever._ui.keymaps.set").safe_set_keymap("n", mapping.keys, function()
                if type(mapping.action) == "string" then
                    vim.cmd(mapping.action)
                else
                    mapping.action()
                end
                require("ever._core.register").deregister_buffer(bufnr, { skip_go_to_last_buffer = true })
            end, { buffer = bufnr, silent = true, nowait = true, desc = mapping.description })
        end
        return lines
    end
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

local function set_keymaps(bufnr)
    vim.keymap.set("n", "q", function()
        require("ever._core.register").deregister_buffer(bufnr, { skip_go_to_last_buffer = true })
    end, { buffer = bufnr, noremap = true, nowait = true })
end

---@param opts ever.RenderPopupOpts
function M.render_popup(opts)
    local bufnr = require("ever._ui.elements").new_buffer({
        buffer_name = opts.buffer_name,
        win_config = { split = "below" },
        lines = function(new_bufnr)
            if opts.ui_type then
                return get_popup_lines(new_bufnr, opts.ui_type, opts.title)
            elseif opts.mappings then
                return get_popup_lines(new_bufnr, opts.mappings, opts.title)
            end
        end,
    })
    set_popup_settings()
    highlight(bufnr)
    set_keymaps(bufnr)
    return bufnr
end

return M
