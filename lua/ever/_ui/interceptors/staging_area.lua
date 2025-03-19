-- Staging area render

local M = {}

local DIFF_BUFNR_UNSTAGED = nil
local DIFF_BUFNR_STAGED = nil
local CURRENT_DIFF_FILE = nil

-- We can just use the same logic as the status UI
local get_line = require("ever._ui.home_options.status").get_line

local function set_diff_buffer_autocmds(diff_bufnr)
    vim.api.nvim_create_autocmd("BufHidden", {
        desc = "Clean up autodiff variables and buffer",
        buffer = diff_bufnr,
        callback = function()
            DIFF_BUFNR_UNSTAGED = nil
            DIFF_BUFNR_STAGED = nil
            CURRENT_DIFF_FILE = nil
        end,
    })
end

---@param status string
---@param filename string
---@return { unstaged_diff_cmd: string, staged_diff_cmd: string }
local function get_diff_cmd(status, filename)
    if require("ever._core.git").is_untracked(status) then
        return {
            unstaged_diff_cmd = "git diff --no-index /dev/null -- " .. filename,
            staged_diff_cmd = "git diff -- " .. filename,
        }
    end
    return {
        unstaged_diff_cmd = "git diff -- " .. filename,
        staged_diff_cmd = "git diff --staged -- " .. filename,
    }
end

---@param bufnr integer
---@param is_staged boolean
local function set_diff_keymaps(bufnr, is_staged)
    require("ever._ui.interceptors.diff.diff_keymaps").set_keymaps(bufnr)
    local keymaps = require("ever._ui.keymaps.base").get_keymaps(bufnr, "diff", {})
    local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }
    require("ever._ui.interceptors.diff.diff_keymaps").set_keymaps(bufnr)
    local set = require("ever._ui.keymaps.set").safe_set_keymap

    set("n", keymaps.stage_hunk, function()
        local hunk = require("ever._ui.interceptors.diff.hunk").extract()
        if not hunk then
            return
        end
        local cmd
        if is_staged then
            cmd = "git apply --reverse --cached --whitespace=nowarn -"
        else
            cmd = "git apply --cached --whitespace=nowarn -"
        end
        require("ever._core.run_cmd").run_cmd(cmd, { stdin = hunk.patch_lines, rerender = true })
    end, keymap_opts)

    set("n", keymaps.stage_line, function()
        local hunk = require("ever._ui.interceptors.diff.hunk").extract()
        if not hunk or not hunk.patch_single_line then
            return
        end
        local cmd
        if is_staged then
            cmd = "git apply --reverse --cached --whitespace=nowarn -"
        else
            cmd = "git apply --cached --whitespace=nowarn -"
        end
        require("ever._core.run_cmd").run_cmd(cmd, { stdin = hunk.patch_single_line, rerender = true })
    end, keymap_opts)
end

---@param bufnr integer
---@param cmd string
---@param diff_type "unstaged" | "staged"
local function setup_diff_buffer(bufnr, cmd, diff_type)
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end
    require("ever._core.register").register_buffer(bufnr, {
        render_fn = function()
            require("ever._ui.stream").stream_lines(bufnr, cmd, {})
        end,
    })
    set_diff_buffer_autocmds(bufnr)
    if diff_type == "unstaged" then
        set_diff_keymaps(bufnr, false)
    else
        set_diff_keymaps(bufnr, true)
    end
end

---@param bufnr integer
local function set_autocmds(bufnr)
    vim.api.nvim_create_autocmd("CursorMoved", {
        desc = "Diff the file under the cursor",
        buffer = bufnr,
        callback = function()
            local line_data = get_line(bufnr)
            if not line_data or line_data.filename == CURRENT_DIFF_FILE then
                return
            end
            CURRENT_DIFF_FILE = line_data.filename
            if DIFF_BUFNR_UNSTAGED and vim.api.nvim_buf_is_valid(DIFF_BUFNR_UNSTAGED) then
                vim.api.nvim_buf_delete(DIFF_BUFNR_UNSTAGED, { force = true })
            end
            if DIFF_BUFNR_STAGED and vim.api.nvim_buf_is_valid(DIFF_BUFNR_STAGED) then
                vim.api.nvim_buf_delete(DIFF_BUFNR_STAGED, { force = true })
            end
            local win = vim.api.nvim_get_current_win()
            local diff_cmds = get_diff_cmd(line_data.status, line_data.safe_filename)

            DIFF_BUFNR_UNSTAGED = require("ever._ui.elements").new_buffer({
                filetype = "git",
                buffer_name = "EverDiffUnstaged--" .. line_data.filename .. ".git",
                win_config = { split = "below", height = math.floor(vim.o.lines * 0.67) },
            })
            require("ever._ui.stream").stream_lines(DIFF_BUFNR_UNSTAGED, diff_cmds.unstaged_diff_cmd, {})
            DIFF_BUFNR_STAGED = require("ever._ui.elements").new_buffer({
                filetype = "git",
                buffer_name = "EverDiffStaged--" .. line_data.filename .. ".git",
                win_config = { split = "right" },
            })
            require("ever._ui.stream").stream_lines(DIFF_BUFNR_STAGED, diff_cmds.staged_diff_cmd, {})
            setup_diff_buffer(DIFF_BUFNR_UNSTAGED, diff_cmds.unstaged_diff_cmd, "unstaged")
            setup_diff_buffer(DIFF_BUFNR_STAGED, diff_cmds.staged_diff_cmd, "staged")
            vim.api.nvim_set_current_win(win)
        end,
        group = vim.api.nvim_create_augroup("EverDiffAutoDiff", { clear = true }),
    })

    vim.api.nvim_create_autocmd({ "BufHidden" }, {
        desc = "Close open diffs when buffer is hidden",
        buffer = bufnr,
        callback = function()
            if DIFF_BUFNR_UNSTAGED and vim.api.nvim_buf_is_valid(DIFF_BUFNR_UNSTAGED) then
                vim.api.nvim_buf_delete(DIFF_BUFNR_UNSTAGED, { force = true })
                DIFF_BUFNR_UNSTAGED = nil
            end
            if DIFF_BUFNR_STAGED and vim.api.nvim_buf_is_valid(DIFF_BUFNR_STAGED) then
                vim.api.nvim_buf_delete(DIFF_BUFNR_STAGED, { force = true })
                DIFF_BUFNR_STAGED = nil
            end
            CURRENT_DIFF_FILE = nil
        end,
        group = vim.api.nvim_create_augroup("EverDiffCloseAutoDiff", { clear = true }),
    })
end

---@param bufnr integer
---@param opts ever.UiRenderOpts
local function set_keymaps(bufnr, opts)
    opts.keymap_opts = { auto_display_keymaps = false }
    require("ever._ui.home_options.status").set_keymaps(bufnr, opts)
end

---@return integer -- created bufnr
M.render = function()
    local opts = { start_line = 1 }
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, bufnr)
    require("ever._ui.home_options.status").set_lines(bufnr, opts)
    set_keymaps(bufnr, opts)
    set_autocmds(bufnr)
    return bufnr
end

function M.cleanup(bufnr)
    CURRENT_DIFF_FILE = nil
    vim.api.nvim_clear_autocmds({ buffer = bufnr, group = "EverDiffAutoDiff" })
    vim.api.nvim_clear_autocmds({ buffer = bufnr, group = "EverDiffCloseAutoDiff" })
    if DIFF_BUFNR_UNSTAGED then
        require("ever._core.register").deregister_buffer(DIFF_BUFNR_UNSTAGED)
        DIFF_BUFNR_UNSTAGED = nil
    end
    if DIFF_BUFNR_STAGED then
        require("ever._core.register").deregister_buffer(DIFF_BUFNR_STAGED)
        DIFF_BUFNR_STAGED = nil
    end
    require("ever._core.register").deregister_buffer(bufnr)
end

return M
