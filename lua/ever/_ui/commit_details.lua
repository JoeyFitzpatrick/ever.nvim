-- Commit details

---@class ever.CommitDetailsLineData
---@field filename string
---@field safe_filename string

local M = {}

local DIFF_BUFNR = nil
local CURRENT_DIFF_FILE = nil

---@param bufnr integer
---@param commit string
function M.set_lines(bufnr, commit)
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end
    local output = require("ever._core.run_cmd").run_cmd("git diff-tree --no-commit-id --name-only " .. commit .. " -r")
    vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, output)
    vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
end

---@param bufnr integer
---@param line_num? integer
---@return ever.CommitDetailsLineData| nil
function M.get_line(bufnr, line_num)
    line_num = line_num or vim.api.nvim_win_get_cursor(0)[1]
    local filename = vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1]
    if not filename or filename == "" then
        return nil
    end
    return { filename = filename, safe_filename = "'" .. filename .. "'" }
end

---@param bufnr integer
---@param commit string
local function set_keymaps(bufnr, commit)
    vim.print(bufnr, commit)
    -- TODO: add keymaps
    -- local keymaps = require("ever._ui.keymaps.base").get_ui_keymaps(bufnr, "commit_details")
    -- local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }
end

local function set_diff_buffer_autocmds(diff_bufnr)
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
        desc = "Stop insert mode on buf enter",
        buffer = diff_bufnr,
        command = "stopinsert",
        group = vim.api.nvim_create_augroup("EverCommitDetailsUi", { clear = false }),
    })
    vim.api.nvim_create_autocmd("BufHidden", {
        desc = "Clean up diff variables",
        buffer = diff_bufnr,
        callback = function()
            DIFF_BUFNR = nil
            CURRENT_DIFF_FILE = nil
        end,
    })
end

---@param bufnr integer
---@param commit string
local function set_autocmds(bufnr, commit)
    vim.api.nvim_create_autocmd("CursorMoved", {
        desc = "Diff the file under the cursor",
        buffer = bufnr,
        callback = function()
            local line_data = M.get_line(bufnr)
            if not line_data or line_data.filename == CURRENT_DIFF_FILE then
                return
            end
            CURRENT_DIFF_FILE = line_data.filename
            if DIFF_BUFNR then
                vim.api.nvim_buf_delete(DIFF_BUFNR, { force = true })
                DIFF_BUFNR = nil
            end
            local win = vim.api.nvim_get_current_win()
            require("ever._ui.elements").terminal(
                "show " .. commit .. " -- " .. line_data.safe_filename,
                { display_strategy = "right", insert = false }
            )
            DIFF_BUFNR = vim.api.nvim_get_current_buf()
            set_diff_buffer_autocmds(DIFF_BUFNR)
            vim.api.nvim_set_current_win(win)
        end,
        group = vim.api.nvim_create_augroup("EverCommitDetailsAutoDiff", { clear = true }),
    })

    vim.api.nvim_create_autocmd("BufHidden", {
        desc = "Close open diffs when buffer is hidden",
        buffer = bufnr,
        callback = function()
            if DIFF_BUFNR then
                vim.api.nvim_buf_delete(DIFF_BUFNR, { force = true })
                DIFF_BUFNR = nil
            end
            CURRENT_DIFF_FILE = nil
        end,
        group = vim.api.nvim_create_augroup("EverCommitDetailsCloseAutoDiff", { clear = true }),
    })
end

---@param commit string
function M.render(commit)
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, bufnr)
    M.set_lines(bufnr, commit)
    set_autocmds(bufnr, commit)
    set_keymaps(bufnr, commit)
end

function M.cleanup(bufnr)
    require("ever._core.register").deregister_buffer(bufnr)
    if DIFF_BUFNR then
        vim.api.nvim_buf_delete(DIFF_BUFNR, { force = true })
        DIFF_BUFNR = nil
    end
    CURRENT_DIFF_FILE = nil
    vim.api.nvim_clear_autocmds({ buffer = bufnr, group = "EverCommitDetailsAutoDiff" })
    vim.api.nvim_clear_autocmds({ buffer = bufnr, group = "EverCommitDetailsCloseAutoDiff" })
end

return M
