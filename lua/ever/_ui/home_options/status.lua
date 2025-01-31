-- Status rendering

local M = {}

local DIFF_BUFNR = nil
local DIFF_CHANNEL_ID = nil
local CURRENT_DIFF_FILE = nil

local function get_status(line)
    return line:sub(1, 2)
end

--- Highlight status lines
---@param bufnr integer
---@param start_line integer
---@param lines string[]
local function highlight(bufnr, start_line, lines)
    local highlight_groups = require("ever._constants.highlight_groups").highlight_groups
    for line_num, line in ipairs(lines) do
        local highlight_group
        local status = get_status(line)
        if require("ever._core.git").is_staged(status) then
            highlight_group = highlight_groups.EVER_DIFF_ADD
        elseif require("ever._core.git").is_modified(status) then
            highlight_group = highlight_groups.EVER_DIFF_MODIFIED
        else
            highlight_group = highlight_groups.EVER_DIFF_REMOVE
        end
        vim.api.nvim_buf_add_highlight(bufnr, -1, highlight_group, line_num + start_line - 1, 0, 2)
    end
end

---@param bufnr integer
---@param opts ever.UiRenderOpts
---@return string[]
local function set_lines(bufnr, opts)
    local start_line = opts.start_line or 0
    local output = require("ever._core.run_cmd").run_cmd("git status --porcelain --untracked")
    vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
    vim.api.nvim_buf_set_lines(bufnr, start_line, -1, false, output)
    vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
    highlight(bufnr, start_line, output)
    return output
end

---@param bufnr integer
---@param line_num? integer
---@return { filename: string, safe_filename: string, status: string } | nil
local function get_line(bufnr, line_num)
    line_num = line_num or vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1]
    if line == "" then
        return nil
    end
    local filename = line:sub(4)
    return { filename = filename, safe_filename = "'" .. filename .. "'", status = get_status(line) }
end

---@param bufnr integer
---@param opts ever.UiRenderOpts
local function set_keymaps(bufnr, opts)
    local keymaps = require("ever._core.configuration").DATA.keymaps.status
    local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }

    vim.keymap.set("n", keymaps.stage, function()
        local line_data = get_line(bufnr)
        if not line_data then
            return
        end
        local result
        if not require("ever._core.git").is_staged(line_data.status) then
            result = require("ever._core.run_cmd").run_hidden_cmd("git add -- " .. line_data.filename)
        else
            result = require("ever._core.run_cmd").run_hidden_cmd("git reset HEAD -- " .. line_data.filename)
        end
        if result == "error" then
            return
        end
        set_lines(bufnr, opts)
    end, keymap_opts)

    vim.keymap.set("n", keymaps.stage_all, function()
        for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, opts.start_line or 0, -1, false)) do
            if line:match("^.%S") then
                require("ever._core.run_cmd").run_hidden_cmd("git add -A")
                set_lines(bufnr, opts)
                return
            end
        end
        require("ever._core.run_cmd").run_hidden_cmd("git reset")
        set_lines(bufnr, opts)
    end, keymap_opts)

    local keymap_to_command_map = {
        { keymap = keymaps.commit, command = "commit" },
        { keymap = keymaps.pull, command = "pull" },
        { keymap = keymaps.push, command = "push" },
    }

    for _, mapping in ipairs(keymap_to_command_map) do
        vim.keymap.set("n", mapping.keymap, function()
            vim.cmd("G " .. mapping.command)
        end, keymap_opts)
    end

    vim.keymap.set("n", keymaps.edit_file, function()
        local line_data = get_line(bufnr)
        if not line_data then
            return
        end
        vim.api.nvim_exec2("e " .. line_data.filename, {})
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

    vim.keymap.set("n", keymaps.restore, function()
        local line_data = get_line(bufnr)
        if not line_data then
            return
        end
        local filename = line_data.safe_filename
        local status = line_data.status
        local status_checks = require("ever._core.git")
        local cmd
        vim.ui.select(
            { "Just this file", "Nuke working tree", "Hard reset", "Mixed reset", "Soft reset" },
            { prompt = "Git restore type: " },
            function(selection)
                if selection == "Just this file" then
                    if not filename then
                        return
                    end
                    if status_checks.is_untracked(status) then
                        cmd = "git clean -f " .. filename
                    elseif status_checks.is_staged(status) then
                        cmd = "git reset -- " .. filename, "&& git clean -f -- " .. filename
                    else
                        cmd = "git restore -- " .. filename
                    end
                elseif selection == "Nuke working tree" then
                    cmd = "git reset --hard HEAD && git clean -fd"
                elseif selection == "Hard reset" then
                    cmd = "git reset --hard HEAD"
                elseif selection == "Mixed reset" then
                    cmd = "git reset --mixed HEAD"
                elseif selection == "Soft reset" then
                    cmd = "git reset --soft HEAD"
                end
                require("ever._core.run_cmd").run_hidden_cmd(cmd)
                set_lines(bufnr, opts)
            end
        )
    end, keymap_opts)
end

local function get_diff_cmd(status, filename)
    local status_checks = require("ever._core.git")
    if status_checks.is_untracked(status) then
        return "diff --no-index /dev/null " .. filename
    end
    if status_checks.is_deleted(status) then
        if status_checks.is_staged(status) then
            return "diff --cached -- " .. filename
        end
        return "diff -- " .. filename
    end
    if status_checks.is_staged(status) then
        return "diff --staged " .. filename
    end
    return "diff " .. filename
end

local function set_diff_buffer_autocmds(diff_bufnr)
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
        desc = "Stop insert mode on buf enter",
        buffer = diff_bufnr,
        command = "stopinsert",
        group = vim.api.nvim_create_augroup("EverStatusUi", { clear = false }),
    })
    vim.api.nvim_create_autocmd("BufHidden", {
        desc = "Clean up diff variables",
        buffer = diff_bufnr,
        callback = function()
            DIFF_BUFNR = nil
            DIFF_CHANNEL_ID = nil
            CURRENT_DIFF_FILE = nil
        end,
    })
end

---@param bufnr integer
---@param opts ever.UiRenderOpts
local function set_autocmds(bufnr, opts)
    vim.api.nvim_create_autocmd("CursorMoved", {
        desc = "Diff the file under the cursor",
        buffer = bufnr,
        callback = function()
            local line_data = get_line(bufnr)
            if not line_data or line_data.filename == CURRENT_DIFF_FILE then
                return
            end
            local diff_cmd = get_diff_cmd(line_data.status, line_data.safe_filename)
            CURRENT_DIFF_FILE = line_data.filename
            if DIFF_BUFNR then
                vim.api.nvim_buf_delete(DIFF_BUFNR, { force = true })
                DIFF_BUFNR = nil
            end
            local win = vim.api.nvim_get_current_win()
            DIFF_CHANNEL_ID = require("ever._ui.elements").terminal(diff_cmd)
            DIFF_BUFNR = vim.api.nvim_get_current_buf()
            set_diff_buffer_autocmds(DIFF_BUFNR)
            vim.api.nvim_set_current_win(win)
        end,
        group = vim.api.nvim_create_augroup("EverStatusAutoDiff", { clear = true }),
    })

    vim.api.nvim_create_autocmd("BufHidden", {
        desc = "Close open diffs when buffer is hidden",
        buffer = bufnr,
        callback = function()
            if DIFF_BUFNR then
                vim.api.nvim_buf_delete(DIFF_BUFNR, { force = true })
                DIFF_BUFNR = nil
            end
            DIFF_CHANNEL_ID = nil
            CURRENT_DIFF_FILE = nil
        end,
        group = vim.api.nvim_create_augroup("EverStatusCloseAutoDiff", { clear = true }),
    })
end

---@param bufnr integer
---@param opts ever.UiRenderOpts
function M.render(bufnr, opts)
    set_lines(bufnr, opts)
    set_autocmds(bufnr, opts)
    set_keymaps(bufnr, opts)
end

function M.cleanup(bufnr)
    require("ever._core.register").deregister_buffer(bufnr)
    if DIFF_BUFNR then
        vim.api.nvim_buf_delete(DIFF_BUFNR, { force = true })
        DIFF_BUFNR = nil
    end
    DIFF_CHANNEL_ID = nil
    CURRENT_DIFF_FILE = nil
    vim.api.nvim_clear_autocmds({ buffer = bufnr, group = "EverStatusAutoDiff" })
    vim.api.nvim_clear_autocmds({ buffer = bufnr, group = "EverStatusCloseAutoDiff" })
end

return M
