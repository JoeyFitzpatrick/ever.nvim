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
---@param cmd string
local function set_diff_buf_lines(bufnr, cmd)
    -- TODO: make diff highlighting look better
    -- Use treesitter highlighting instead of native git
    -- Remove first char from diff lines
    -- add signcolumns
    -- and prevent lsp from attaching
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end
    local diff_lines = require("ever._core.run_cmd").run_cmd(cmd)
    vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, diff_lines)
    vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
end

---@param bufnr integer
---@param is_staged boolean
local function set_diff_keymaps(bufnr, is_staged)
    local keymaps = require("ever._ui.keymaps.base").get_ui_keymaps(bufnr, "diff")
    local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }

    vim.keymap.set("n", keymaps.next_hunk, function()
        local hunk = require("ever._ui.interceptors.diff.hunk").extract()
        if not hunk then
            local cursor = vim.api.nvim_win_get_cursor(0)
            for line_num, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, cursor[1] - 1, -1, false)) do
                if line:sub(1, 2) == "@@" then
                    vim.api.nvim_win_set_cursor(0, { line_num + 1, cursor[2] })
                    return
                end
            end
            return
        end
        if hunk.next_hunk_start == nil then
            return
        end
        local cursor = vim.api.nvim_win_get_cursor(0)
        vim.api.nvim_win_set_cursor(0, { hunk.next_hunk_start, cursor[2] })
    end, keymap_opts)

    vim.keymap.set("n", keymaps.previous_hunk, function()
        local hunk = require("ever._ui.interceptors.diff.hunk").extract()
        if not hunk or hunk.previous_hunk_start == nil then
            return
        end
        local cursor = vim.api.nvim_win_get_cursor(0)
        vim.api.nvim_win_set_cursor(0, { hunk.previous_hunk_start, cursor[2] })
    end, keymap_opts)

    vim.keymap.set("n", keymaps.stage_hunk, function()
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

    vim.keymap.set("n", keymaps.stage_line, function()
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
---@param filename string
---@param diff_type "unstaged" | "staged"
local function setup_diff_buffer(bufnr, cmd, filename, diff_type)
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end
    if diff_type == "unstaged" then
        vim.api.nvim_open_win(bufnr, true, { split = "below", height = math.floor(vim.o.lines * 0.67) })
        pcall(vim.api.nvim_buf_set_name, bufnr, "EverDiffUnstaged--" .. filename .. ".git")
    else
        vim.api.nvim_open_win(bufnr, true, { split = "right" })
        pcall(vim.api.nvim_buf_set_name, bufnr, "EverDiffStaged--" .. filename .. ".git")
    end

    vim.api.nvim_set_option_value("filetype", "git", { buf = bufnr })
    set_diff_buf_lines(bufnr, cmd)
    require("ever._core.register").register_buffer(bufnr, {
        render_fn = function()
            set_diff_buf_lines(bufnr, cmd)
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
            DIFF_BUFNR_UNSTAGED = vim.api.nvim_create_buf(false, true)
            DIFF_BUFNR_STAGED = vim.api.nvim_create_buf(false, true)
            local diff_cmds = get_diff_cmd(line_data.status, line_data.safe_filename)
            setup_diff_buffer(DIFF_BUFNR_UNSTAGED, diff_cmds.unstaged_diff_cmd, line_data.filename, "unstaged")
            setup_diff_buffer(DIFF_BUFNR_STAGED, diff_cmds.staged_diff_cmd, line_data.filename, "staged")
            vim.api.nvim_set_current_win(win)
        end,
        group = vim.api.nvim_create_augroup("EverDiffAutoDiff", { clear = true }),
    })

    vim.api.nvim_create_autocmd({ "BufWipeout" }, {
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

local function set_keymaps(bufnr)
    local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }

    vim.keymap.set("n", "q", function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end, keymap_opts)
end

---@return integer -- created bufnr
M.render = function()
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, bufnr)
    require("ever._ui.home_options.status").set_lines(bufnr, { start_line = 0 })
    set_keymaps(bufnr)
    set_autocmds(bufnr)
    return bufnr
end

function M.cleanup(bufnr)
    if DIFF_BUFNR_UNSTAGED then
        vim.api.nvim_buf_delete(DIFF_BUFNR_UNSTAGED, { force = true })
        DIFF_BUFNR_UNSTAGED = nil
    end
    if DIFF_BUFNR_STAGED and vim.api.nvim_buf_is_valid(DIFF_BUFNR_STAGED) then
        vim.api.nvim_buf_delete(DIFF_BUFNR_STAGED, { force = true })
        DIFF_BUFNR_STAGED = nil
    end
    CURRENT_DIFF_FILE = nil
    vim.api.nvim_clear_autocmds({ buffer = bufnr, group = "EverDiffAutoDiff" })
    vim.api.nvim_clear_autocmds({ buffer = bufnr, group = "EverDiffCloseAutoDiff" })
    if DIFF_BUFNR_UNSTAGED then
        require("ever._core.register").deregister_buffer(DIFF_BUFNR_UNSTAGED)
    end
    if DIFF_BUFNR_STAGED then
        require("ever._core.register").deregister_buffer(DIFF_BUFNR_STAGED)
    end
    require("ever._core.register").deregister_buffer(bufnr)
end

return M
