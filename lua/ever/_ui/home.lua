---@class TabHighlightIndices
---@field start integer
---@field ending integer

local M = {}

--- Creates tabs for home UI
---@param options string[]
---@return string[], TabHighlightIndices[]
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

    return boxes, indices
end

local options = { "Status", "Branch", "Log", "Stash" }
local tabs_text, tab_indices = M._create_box_table(options)

local tabs = {
    options = options,
    tab_indices = tab_indices,
    current = 1,
    ---@param direction "forward" | "back"
    cycle_tab = function(self, direction)
        if direction == "forward" then
            if self.current >= #self.options then
                self.current = 1
            else
                self.current = self.current + 1
            end
        else
            if self.current <= 1 then
                self.current = #self.options
            else
                self.current = self.current - 1
            end
        end
        return self.tab_indices[self.current]
    end,
}

local highlight_namespace = vim.api.nvim_create_namespace("EverHomeTabs")

---@param bufnr integer
---@param indices TabHighlightIndices[]
local function highlight_tabs(bufnr, indices)
    vim.api.nvim_buf_clear_namespace(bufnr, highlight_namespace, 0, 3)
    for i = 1, 3 do
        vim.api.nvim_buf_add_highlight(bufnr, highlight_namespace, "Conceal", i - 1, 1, indices[i].start - 4)
        vim.api.nvim_buf_add_highlight(bufnr, highlight_namespace, "Conceal", i - 1, indices[i].ending, -1)
    end
end

function M.open()
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, bufnr)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, tabs_text)
    tabs.current = 1 -- TODO: move this into on-close autocmd once we have that
    highlight_tabs(bufnr, tabs.tab_indices[tabs.current])
    require("lua.ever._ui.keymaps.base").set_keymaps(bufnr, "home")
    vim.keymap.set("n", "<Tab>", function()
        local current_tab_indices = tabs:cycle_tab("forward")
        highlight_tabs(bufnr, current_tab_indices)
    end, { buffer = bufnr })
    vim.keymap.set("n", "<S-Tab>", function()
        local current_tab_indices = tabs:cycle_tab("back")
        highlight_tabs(bufnr, current_tab_indices)
    end, { buffer = bufnr })
end

return M
