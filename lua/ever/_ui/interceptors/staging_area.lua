-- Staging area render

---@class ever.StagingAreaSetupDiffParams
---@field bufnr integer
---@field win integer
---@field diff_type "unstaged" | "staged"
---@field filename string

local M = {}

local UNSTAGED_BUFNR = nil
local STAGED_BUFNR = nil
local CURRENT_DIFF_FILE = nil

-- We can just use the same logic as the status UI
local get_line = require("ever._ui.home_options.status").get_line

local function set_diff_buffer_autocmds(diff_bufnr)
    vim.api.nvim_create_autocmd("BufHidden", {
        desc = "Clean up autodiff variables and buffer",
        buffer = diff_bufnr,
        callback = function()
            UNSTAGED_BUFNR = nil
            STAGED_BUFNR = nil
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
    local keymaps = require("ever._ui.keymaps.base").get_keymaps(bufnr, "diff", { skip_go_to_last_buffer = true })
    local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }
    local set = require("ever._ui.keymaps.set").safe_set_keymap

    -- Normally, get_keymaps sets the "q" keymap.
    -- In this case, we want it to close both diff buffers
    -- So we need to set it here
    set("n", "q", function()
        require("ever._core.register").deregister_buffer(STAGED_BUFNR, { skip_go_to_last_buffer = true })
        require("ever._core.register").deregister_buffer(UNSTAGED_BUFNR, { skip_go_to_last_buffer = true })
        -- At this point, we are in the staging area files buffer
        -- We want to close it and navigate back to the last non-staging-area buffer
        require("ever._core.register").deregister_buffer(0, { skip_go_to_last_buffer = false })
    end, keymap_opts)

    ---@param mode "n" | "v"
    local function stage_keymap(mode)
        local hunk = require("ever._ui.interceptors.diff.hunk").extract(is_staged)
        if not hunk then
            return
        end
        local cmd
        if is_staged then
            cmd = "git apply --reverse --cached --whitespace=fix -"
        else
            cmd = "git apply --cached --whitespace=fix -"
        end
        require("ever._core.run_cmd").run_cmd(
            cmd,
            { stdin = mode == "v" and hunk.patch_selected_lines or hunk.patch_lines, rerender = true }
        )
    end

    set("n", keymaps.stage, function()
        stage_keymap("n")
    end, keymap_opts)

    set("v", keymaps.stage, function()
        stage_keymap("v")
    end, keymap_opts)
end

---@param args ever.StagingAreaSetupDiffParams
local function setup_diff_buffer(args)
    local bufnr = args.bufnr
    local win = args.win
    local filename = args.filename
    local diff_type = args.diff_type
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end
    require("ever._core.register").register_buffer(bufnr, {
        render_fn = function()
            local win_valid, original_cursor_pos = pcall(vim.api.nvim_win_get_cursor, win)
            if
                not CURRENT_DIFF_FILE
                or args.filename ~= require("ever._core.texter").surround_with_quotes(CURRENT_DIFF_FILE)
            then
                return
            end
            local status_output = require("ever._core.run_cmd").run_cmd("git status --porcelain -- " .. filename)
            if not status_output[1] then
                return
            end
            local status = status_output[1]:sub(1, 2)
            local diff_cmds = get_diff_cmd(status, filename)
            require("ever._ui.stream").stream_lines(
                bufnr,
                diff_type == "staged" and diff_cmds.staged_diff_cmd or diff_cmds.unstaged_diff_cmd,
                { silent = true }
            )
            vim.defer_fn(function()
                if not win_valid then
                    return
                end
                local ok = pcall(vim.api.nvim_win_set_cursor, win, original_cursor_pos)
                local cursor_start_pos
                if ok then
                    cursor_start_pos = original_cursor_pos[1]
                else
                    cursor_start_pos = 0
                end
                pcall(function()
                    local start = cursor_start_pos
                    local stop = 5 -- Always the location of a hunk start (@@) if there is one
                    local step = start < stop and 1 or -1 -- Always move towards stop from start
                    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, cursor_start_pos + 6, false)
                    for i = start, stop, step do
                        local line = lines[i]
                        if line:match("^@@") then
                            vim.api.nvim_win_set_cursor(win, { i, 0 })
                            return
                        end
                    end
                    vim.api.nvim_win_set_cursor(win, { cursor_start_pos, 0 })
                end)
            end, 100)
        end,
    })
    set_diff_buffer_autocmds(bufnr)
    if args.diff_type == "unstaged" then
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
            local line_data = get_line(bufnr, 0)
            if not line_data or line_data.filename == CURRENT_DIFF_FILE then
                return
            end
            CURRENT_DIFF_FILE = line_data.filename
            local filename = line_data.safe_filename

            if UNSTAGED_BUFNR and vim.api.nvim_buf_is_valid(UNSTAGED_BUFNR) then
                vim.api.nvim_buf_delete(UNSTAGED_BUFNR, { force = true })
            end
            if STAGED_BUFNR and vim.api.nvim_buf_is_valid(STAGED_BUFNR) then
                vim.api.nvim_buf_delete(STAGED_BUFNR, { force = true })
            end
            local win = vim.api.nvim_get_current_win()
            local diff_cmds = get_diff_cmd(line_data.status, filename)

            local unstaged_win
            UNSTAGED_BUFNR, unstaged_win = require("ever._ui.elements").new_buffer({
                filetype = "git",
                buffer_name = "EverDiffUnstaged--" .. line_data.filename .. ".git",
                win_config = { split = "below", height = math.floor(vim.o.lines * 0.67) },
            })
            require("ever._ui.stream").stream_lines(UNSTAGED_BUFNR, diff_cmds.unstaged_diff_cmd, {
                silent = true,
            })

            local staged_win
            STAGED_BUFNR, staged_win = require("ever._ui.elements").new_buffer({
                filetype = "git",
                buffer_name = "EverDiffStaged--" .. line_data.filename .. ".git",
                win_config = { split = "right" },
            })
            require("ever._ui.stream").stream_lines(STAGED_BUFNR, diff_cmds.staged_diff_cmd, { silent = true })
            setup_diff_buffer({
                bufnr = UNSTAGED_BUFNR,
                win = unstaged_win,
                diff_type = "unstaged",
                filename = filename,
            })
            setup_diff_buffer({ bufnr = STAGED_BUFNR, win = staged_win, diff_type = "staged", filename = filename })
            vim.api.nvim_set_current_win(win)
        end,
        group = vim.api.nvim_create_augroup("EverDiffAutoDiff", { clear = true }),
    })

    vim.api.nvim_create_autocmd({ "BufHidden" }, {
        desc = "Close open diffs when buffer is hidden",
        buffer = bufnr,
        callback = function()
            if UNSTAGED_BUFNR and vim.api.nvim_buf_is_valid(UNSTAGED_BUFNR) then
                vim.api.nvim_buf_delete(UNSTAGED_BUFNR, { force = true })
                UNSTAGED_BUFNR = nil
            end
            if STAGED_BUFNR and vim.api.nvim_buf_is_valid(STAGED_BUFNR) then
                vim.api.nvim_buf_delete(STAGED_BUFNR, { force = true })
                STAGED_BUFNR = nil
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
    local bufnr = require("ever._ui.elements").new_buffer({
        buffer_name = "EverStagingArea",
    })
    require("ever._ui.home_options.status").set_lines(bufnr, {})
    set_keymaps(bufnr, {})
    set_autocmds(bufnr)
    return bufnr
end

return M
