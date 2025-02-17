local M = {}

local MAP_SYMBOL = "⟶"

---@param bufnr integer
local function set_terminal_keymaps(bufnr)
    local opts = { buffer = bufnr }

    vim.keymap.set("n", "q", function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end, opts)

    vim.keymap.set("n", "<enter>", function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end, opts)
end

--- Set the appropriate keymaps for a given command and element.
---@param bufnr integer
---@param element ever.ElementType -- Element type, e.g. "terminal"
function M.set_keymaps(bufnr, element)
    if element == "terminal" then
        set_terminal_keymaps(bufnr)
    end
end

local function get_max_keymap_length(keymaps)
    local max_keymap_length = 0
    for _, mapping in pairs(keymaps) do
        max_keymap_length = math.max(max_keymap_length, #mapping)
    end
    return max_keymap_length
end

---@param mappings table<string, string>
---@param ui_type string
local function display_keymap_help(mappings, ui_type)
    ---@type string[]
    local keys_to_descriptions = {}
    local descriptions = require("ever._constants.keymap_descriptions")[ui_type]
    local max_keymap_length = get_max_keymap_length(mappings)

    for command, keys in pairs(mappings) do
        local padding = string.rep(" ", max_keymap_length - #keys)
        table.insert(
            keys_to_descriptions,
            string.format("   %s%s %s %s", keys, padding, MAP_SYMBOL, descriptions[command])
        )
    end
    table.sort(keys_to_descriptions)

    local bufnr = vim.api.nvim_create_buf(false, true)
    require("ever._ui.elements").float(bufnr, { title = ui_type .. " keymaps" })

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, keys_to_descriptions)
    for i, line in ipairs(keys_to_descriptions) do
        local keys_start, keys_end = line:find(".+" .. MAP_SYMBOL)
        require("ever._ui.highlight").highlight_line(bufnr, "Function", i - 1, keys_start, keys_end)
    end

    local opts = { buffer = bufnr }

    vim.keymap.set("n", "q", function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end, opts)
end

--- Get ui-specific keymaps, and set up keymap help float
---@param bufnr integer
---@param ui_type string
---@return table<string, string>
function M.get_ui_keymaps(bufnr, ui_type)
    local mappings = require("ever._core.configuration").DATA.keymaps[ui_type]
    assert(mappings ~= nil, "Called `get_ui_keymaps` with an invalid ui type: " .. ui_type)
    local HELP_FLOAT_MAP = "g?"
    vim.keymap.set("n", HELP_FLOAT_MAP, function()
        display_keymap_help(mappings, ui_type)
    end, { buffer = bufnr })
    return mappings
end

return M
