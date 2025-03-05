--Stash ui

---@class ever.StashLineData
---@field stash_index string

local M = {}

local DIFF_BUFNR = nil
local DIFF_CHANNEL_ID = nil
local CURRENT_STASH_INDEX = nil

--- Highlight stash lines
---@param bufnr integer
---@param start_line integer
---@param lines string[]
local function highlight(bufnr, start_line, lines)
    local highlight_line = require("ever._ui.highlight").highlight_line
    for i, line in ipairs(lines) do
        if line == "" then
            return
        end
        local line_num = i + start_line - 1
        local stash_index_start, stash_index_end = line:find("^%S+")
        highlight_line(bufnr, "Keyword", line_num, stash_index_start, stash_index_end)
        local date_start, date_end = line:find(".+ago", stash_index_end + 1)
        highlight_line(bufnr, "Function", line_num, date_start, date_end)
        local branch_start, branch_end = line:find(" .+:", date_end + 1)
        highlight_line(bufnr, "Removed", line_num, branch_start, branch_end)
    end
end

---@param bufnr integer
---@param opts ever.UiRenderOpts
---@return string[]
local function set_lines(bufnr, opts)
    local start_line = opts.start_line or 0
    local output =
        require("ever._core.run_cmd").run_cmd("git stash list --pretty=format:'%<(12)%gd %<(18)%cr   %<(25)%s'")
    vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
    vim.api.nvim_buf_set_lines(bufnr, start_line, -1, false, output)
    vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
    highlight(bufnr, start_line, output)
    return output
end

---@param bufnr integer
---@param line_num? integer
---@return { stash_index: string } | nil
local function get_line(bufnr, line_num)
    line_num = line_num or vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1]
    if line == "" then
        return nil
    end
    return { stash_index = line:match(".+}") }
end

---@param bufnr integer
local function set_keymaps(bufnr)
    local keymaps = require("ever._ui.keymaps.base").get_ui_keymaps(bufnr, "stash")
    local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }

    vim.keymap.set("n", keymaps.apply, function()
        local line_data = get_line(bufnr)
        if not line_data then
            return
        end
        vim.cmd("G stash apply " .. line_data.stash_index)
    end, keymap_opts)

    vim.keymap.set("n", keymaps.drop, function()
        local line_data = get_line(bufnr)
        if not line_data then
            return
        end
        vim.ui.select(
            { "Yes", "No" },
            { prompt = "Are you sure you want to drop " .. line_data.stash_index .. "? " },
            function(selection)
                if selection == "Yes" then
                    vim.cmd("G stash drop " .. line_data.stash_index)
                end
            end
        )
    end, keymap_opts)

    vim.keymap.set("n", keymaps.pop, function()
        local line_data = get_line(bufnr)
        if not line_data then
            return
        end
        vim.cmd("G stash pop " .. line_data.stash_index)
    end, keymap_opts)

    vim.keymap.set("n", keymaps.scroll_diff_down, function()
        if DIFF_BUFNR and DIFF_CHANNEL_ID then
            pcall(vim.api.nvim_chan_send, DIFF_CHANNEL_ID, "jj")
        end
    end, keymap_opts)

    vim.keymap.set("n", keymaps.scroll_diff_up, function()
        if DIFF_BUFNR and DIFF_CHANNEL_ID then
            pcall(vim.api.nvim_chan_send, DIFF_CHANNEL_ID, "kk")
        end
    end, keymap_opts)
end

local function set_diff_buffer_autocmds(diff_bufnr)
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
        desc = "Stop insert mode on buf enter",
        buffer = diff_bufnr,
        command = "stopinsert",
        group = vim.api.nvim_create_augroup("EverAtashUi", { clear = false }),
    })
    vim.api.nvim_create_autocmd("BufHidden", {
        desc = "Clean up diff variables",
        buffer = diff_bufnr,
        callback = function()
            DIFF_BUFNR = nil
            DIFF_CHANNEL_ID = nil
        end,
    })
end

---@param bufnr integer
local function set_autocmds(bufnr)
    vim.api.nvim_create_autocmd("CursorMoved", {
        desc = "Show changes in stash under the cursor",
        buffer = bufnr,
        callback = function()
            local line_data = get_line(bufnr)
            if not line_data or line_data.stash_index == CURRENT_STASH_INDEX then
                return
            end
            CURRENT_STASH_INDEX = line_data.stash_index
            if DIFF_BUFNR then
                vim.api.nvim_buf_delete(DIFF_BUFNR, { force = true })
                DIFF_BUFNR = nil
                DIFF_CHANNEL_ID = nil
            end
            local win = vim.api.nvim_get_current_win()
            DIFF_CHANNEL_ID = require("ever._ui.elements").terminal(
                "stash show -p " .. line_data.stash_index,
                { display_strategy = "right", insert = false }
            )
            DIFF_BUFNR = vim.api.nvim_get_current_buf()
            set_diff_buffer_autocmds(DIFF_BUFNR)
            vim.api.nvim_set_current_win(win)
        end,
        group = vim.api.nvim_create_augroup("EverStashAutoDiff", { clear = true }),
    })

    vim.api.nvim_create_autocmd("BufHidden", {
        desc = "Close open diffs when buffer is hidden",
        buffer = bufnr,
        callback = function()
            if DIFF_BUFNR then
                vim.api.nvim_buf_delete(DIFF_BUFNR, { force = true })
                DIFF_BUFNR = nil
            end
            CURRENT_STASH_INDEX = nil
        end,
        group = vim.api.nvim_create_augroup("EverStashCloseAutoDiff", { clear = true }),
    })
end

---@param bufnr integer
---@param opts ever.UiRenderOpts
function M.render(bufnr, opts)
    set_lines(bufnr, opts)
    set_autocmds(bufnr)
    set_keymaps(bufnr)
end

function M.cleanup(bufnr)
    require("ever._core.register").deregister_buffer(bufnr)
end

return M
