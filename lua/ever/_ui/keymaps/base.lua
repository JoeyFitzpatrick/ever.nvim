---@class ever.SetKeymapsOpts
---@field terminal_channel_id? integer

---@class ever.GetKeymapsOpts
---@field popup? boolean
---@field open_file_keymaps? boolean
---@field auto_display_keymaps? boolean
---@field skip_go_to_last_buffer? boolean

local M = {}

local MAP_SYMBOL = "⟶"

---@param bufnr integer
---@param channel_id integer
local function set_terminal_keymaps(bufnr, channel_id)
    local opts = { buffer = bufnr }

    vim.keymap.set("n", "q", function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end, opts)

    vim.keymap.set("n", "<enter>", function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end, opts)

    vim.keymap.set("n", "J", function()
        vim.api.nvim_chan_send(channel_id, "j")
    end, opts)

    vim.keymap.set("n", "K", function()
        vim.api.nvim_chan_send(channel_id, "k")
    end, opts)

    -- vim.keymap.set("t", "<esc>", function()
    --     vim.cmd("stopinsert")
    -- end, opts)
end

--- Set the appropriate keymaps for a given command and element.
---@param bufnr integer
---@param opts ever.SetKeymapsOpts
function M.set_keymaps(bufnr, opts)
    if opts.terminal_channel_id then
        set_terminal_keymaps(bufnr, opts.terminal_channel_id)
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
---@param opts ever.GetKeymapsOpts
local function display_keymap_help(mappings, ui_type, opts)
    ---@type string[]
    local keys_to_descriptions = {}
    local descriptions = require("ever._constants.keymap_descriptions")[ui_type]
    if opts.open_file_keymaps then
        descriptions = vim.tbl_extend("force", descriptions, require("ever._constants.keymap_descriptions").open_files)
    end
    if opts.auto_display_keymaps then
        descriptions =
            vim.tbl_extend("force", descriptions, require("ever._constants.keymap_descriptions").auto_display)
    end
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

    local keymap_opts = { buffer = bufnr }

    vim.keymap.set("n", "q", function()
        require("ever._core.register").deregister_buffer(bufnr, { skip_go_to_last_buffer = true })
    end, keymap_opts)
end

--- Get ui-specific keymaps, and set up keymap help float
---@param bufnr integer
---@param ui_type string
---@param opts ever.GetKeymapsOpts
---@return table<string, string>
function M.get_keymaps(bufnr, ui_type, opts)
    local mappings = require("ever._core.configuration").DATA[ui_type].keymaps
    assert(mappings ~= nil, "Called `get_ui_keymaps` with an invalid ui type: " .. ui_type)
    if opts.open_file_keymaps then
        mappings = vim.tbl_extend("force", mappings, require("ever._core.configuration").DATA["open_files"].keymaps)
    end
    if opts.auto_display_keymaps then
        mappings = vim.tbl_extend("force", mappings, require("ever._core.configuration").DATA["auto_display"].keymaps)
    end
    if not opts.popup then
        local HELP_FLOAT_MAP = "g?"

        vim.keymap.set("n", HELP_FLOAT_MAP, function()
            display_keymap_help(mappings, ui_type, opts)
        end, { buffer = bufnr })
    end

    vim.keymap.set("n", "q", function()
        require("ever._core.register").deregister_buffer(
            bufnr,
            { skip_go_to_last_buffer = opts.skip_go_to_last_buffer or opts.popup }
        )
    end, { buffer = bufnr })

    return mappings
end

return M
