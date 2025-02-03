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
    local diff_lines = require("ever._core.run_cmd").run_cmd(cmd)
    local highlight_groups = require("ever._constants.highlight_groups").highlight_groups
    local signcolumns = require("ever._constants.signcolumns").signcolumns
    vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
    for i, line in ipairs(diff_lines) do
        local first_char = line:sub(1, 1)
        local is_index_line = line:match("^--- [ab]/") or line:match("^+++ [ab]/") or line:match("^--- /dev/null")
        local is_patch_line = is_index_line or (first_char ~= "+" and first_char ~= "-" and first_char ~= " ")
        -- TODO: figure out how to make this work while still chopping off the first char
        -- Currently the hunk extractor expects diff lines to have "+" and "-"
        vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, { line })
        -- vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, { is_patch_line and line or line:sub(2) })
        local signcolumn_line_num = i + 1
        if is_patch_line then
            vim.api.nvim_buf_add_highlight(bufnr, -1, "Normal", i, 0, -1)
        elseif first_char == "+" then
            vim.api.nvim_buf_add_highlight(bufnr, -1, highlight_groups.EVER_DIFF_ADD_BG, i, 0, -1)
            vim.fn.sign_place(0, signcolumns.EVER_PLUS, signcolumns.EVER_PLUS, bufnr, { lnum = signcolumn_line_num })
        elseif first_char == "-" then
            vim.api.nvim_buf_add_highlight(bufnr, -1, highlight_groups.EVER_DIFF_REMOVE_BG, i, 0, -1)
            vim.fn.sign_place(0, signcolumns.EVER_MINUS, signcolumns.EVER_MINUS, bufnr, { lnum = signcolumn_line_num })
        end
    end
    vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
    -- Remove any lsp that might have tried to attach to the diff buffer
    -- We don't want any diagnostics or anything
    vim.schedule(function()
        for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
            vim.lsp.buf_detach_client(bufnr, client.id)
        end
    end)
end

---@param bufnr integer
---@param is_staged boolean
local function set_diff_keymaps(bufnr, is_staged)
    local keymaps = require("ever._core.configuration").DATA.keymaps.diff
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
        vim.print(cmd)
        local output = require("ever._core.run_cmd").run_cmd(cmd, { stdin = hunk.patch_lines, rerender = true })
        vim.print(output)
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
        pcall(vim.api.nvim_buf_set_name, bufnr, "EverDiffUnstaged--" .. filename)
    else
        vim.api.nvim_open_win(bufnr, true, { split = "right" })
        pcall(vim.api.nvim_buf_set_name, bufnr, "EverDiffStaged--" .. filename)
    end

    -- Sometimes when scrolling fast, there are some treesitter errors. Deferring the filetype change seems to avoid this
    vim.defer_fn(function()
        if not vim.api.nvim_buf_is_valid(bufnr) then
            return
        end
        vim.api.nvim_set_option_value("filetype", vim.filetype.match({ buf = bufnr }), { buf = bufnr })
    end, 10)
    set_diff_buf_lines(bufnr, cmd)
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

M.render = function()
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, bufnr)
    require("ever._ui.home_options.status").set_lines(bufnr, { start_line = 0 })
    set_keymaps(bufnr)
    set_autocmds(bufnr)
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
