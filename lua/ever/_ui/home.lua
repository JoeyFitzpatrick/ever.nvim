---@class ever.TabHighlightIndices
---@field start integer
---@field ending integer

---@alias ever.TabOption "Status" | "Branch" | "Log" | "Stash"

---@class ever.UiRenderOpts
---@field start_line? integer
---@field cmd? string -- The command used for this UI

local M = {}

-- includes padding (two lines currently)
local TAB_HEIGHT = 4

--- Creates tabs for home UI
---@param options string[]
---@return string[], ever.TabHighlightIndices[]
function M._create_box_table(options)
    local boxes = {}
    local indices = {}
    local separator = "  "
    local top_line, middle_line, bottom_line = separator, separator, separator
    local separator_len = separator:len()

    for _, option in ipairs(options) do
        local box_width = math.max(#option + 2, 7)
        local padding = math.floor((box_width - #option) / 2)

        ---@type string
        local top_str_to_add = "┌" .. string.rep("─", box_width) .. "┐" .. separator
        top_line = top_line .. top_str_to_add

        local middle_str_to_add = "│"
            .. string.rep(" ", padding)
            .. option
            .. string.rep(" ", box_width - #option - padding)
            .. "│"
            .. separator
        middle_line = middle_line .. middle_str_to_add

        local bottom_str_to_add = "└" .. string.rep("─", box_width) .. "┘" .. separator
        bottom_line = bottom_line .. bottom_str_to_add

        table.insert(indices, {
            {
                start = top_line:len() - top_str_to_add:len() + string.len("┌"),
                ending = top_line:len() - separator_len,
            },
            {
                start = middle_line:len() - middle_str_to_add:len() + string.len("│"),
                ending = middle_line:len() - separator_len,
            },
            {
                start = bottom_line:len() - bottom_str_to_add:len() + string.len("└"),
                ending = bottom_line:len() - separator_len,
            },
        })
    end

    table.insert(boxes, top_line:sub(1, -#separator - 1))
    table.insert(boxes, middle_line:sub(1, -#separator - 1))
    table.insert(boxes, bottom_line:sub(1, -#separator - 1))
    -- Add padding
    table.insert(boxes, "")

    return boxes, indices
end

local TAB_OPTIONS = { "Status", "Branch", "Log", "Stash" }
local tabs_text, tab_indices = M._create_box_table(TAB_OPTIONS)

local tabs = {
    _options = TAB_OPTIONS,
    _tab_indices = tab_indices,
    current = 1,
    current_option = TAB_OPTIONS[1],
    current_tab_indices = tab_indices[1],
    set_current = function(self, index)
        if index < 1 then
            self.current = 1
        elseif index > #self._options then
            self.current = #self.options
        else
            self.current = index
        end
        self.current_option = self._options[self.current]
        self.current_tab_indices = self._tab_indices[self.current]
    end,
    ---@param direction "forward" | "back"
    cycle_tab = function(self, direction)
        if direction == "forward" then
            if self.current >= #self._options then
                self.current = 1
            else
                self.current = self.current + 1
            end
        else
            if self.current <= 1 then
                self.current = #self._options
            else
                self.current = self.current - 1
            end
        end
        self.current_option = self._options[self.current]
        self.current_tab_indices = self._tab_indices[self.current]
    end,
}

local highlight_namespace = vim.api.nvim_create_namespace("EverHomeTabs")

---@param bufnr integer
---@param indices ever.TabHighlightIndices[]
local function highlight_tabs(bufnr, indices)
    vim.api.nvim_buf_clear_namespace(bufnr, highlight_namespace, 0, 3)
    for i = 1, 3 do
        vim.api.nvim_buf_add_highlight(bufnr, highlight_namespace, "Conceal", i - 1, 1, indices[i].start - 4)
        vim.api.nvim_buf_add_highlight(bufnr, highlight_namespace, "Conceal", i - 1, indices[i].ending, -1)
    end
end

---@type table<ever.TabOption, fun(bufnr: integer, opts: ever.UiRenderOpts)>
local tab_render_map = {
    Status = function(bufnr, opts)
        require("ever._ui.home_options.status").render(bufnr, opts)
    end,
    Branch = function(bufnr, opts)
        require("ever._ui.home_options.branch").render(bufnr, opts)
    end,
    Log = function(bufnr, opts)
        require("ever._ui.home_options.log").render(bufnr, opts)
    end,
    Stash = function(bufnr, opts)
        require("ever._ui.home_options.stash").render(bufnr, opts)
    end,
}

local tab_cleanup_map = {
    Status = function(bufnr)
        require("ever._ui.home_options.status").cleanup(bufnr)
    end,
    Branch = function(bufnr)
        require("ever._ui.home_options.branch").cleanup(bufnr)
    end,
    Log = function(bufnr)
        require("ever._ui.home_options.log").cleanup(bufnr)
    end,
    Stash = function(bufnr)
        require("ever._ui.home_options.stash").cleanup(bufnr)
    end,
}

---@param tab ever.TabOption
---@param indices ever.TabHighlightIndices[]
local function create_and_render_buffer(tab, indices)
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, bufnr)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, tabs_text)

    local ui_render = tab_render_map[tab]
    vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
    ui_render(bufnr, { start_line = TAB_HEIGHT })
    vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
    vim.api.nvim_win_set_cursor(0, { math.min(vim.api.nvim_buf_line_count(bufnr), 5), 0 })
    highlight_tabs(bufnr, indices)
    require("ever._core.register").register_buffer(bufnr, {
        render_fn = function()
            ui_render(bufnr, { start_line = TAB_HEIGHT })
        end,
    })

    local keymaps = require("ever._core.configuration").DATA.home.keymaps
    vim.keymap.set("n", "q", function()
        tab_cleanup_map[tabs.current_option](bufnr)
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end, { buffer = bufnr })

    vim.keymap.set("n", keymaps.next, function()
        local old_bufnr = bufnr
        tab_cleanup_map[tabs.current_option](old_bufnr)
        tabs:cycle_tab("forward")
        create_and_render_buffer(tabs.current_option, tabs.current_tab_indices)
        vim.api.nvim_buf_delete(old_bufnr, { force = true })
    end, { buffer = bufnr })

    vim.keymap.set("n", keymaps.previous, function()
        local old_bufnr = bufnr
        tab_cleanup_map[tabs.current_option](old_bufnr)
        tabs:cycle_tab("back")
        create_and_render_buffer(tabs.current_option, tabs.current_tab_indices)
        vim.api.nvim_buf_delete(old_bufnr, { force = true })
    end, { buffer = bufnr })
end

function M.open()
    tabs:set_current(1) -- TODO: move this into on-close autocmd once we have that
    create_and_render_buffer(tabs.current_option, tabs.current_tab_indices)
end

return M
