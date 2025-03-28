-- Status rendering

---@class ever.StatusLineData
---@field filename string
---@field safe_filename string
---@field status string

local M = {}

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

-- Git sorts files by status, and when a status changes by (un)staging,
-- it can re-order the files, which we don't want.
-- Instead, sort by the filepaths.
-- NOTE: this function sorts the input table in place.
---@param files string[]
function M._sort_status_files(files)
    table.sort(files, function(left, right)
        return left:sub(4) < right:sub(4)
    end)
end

---@param bufnr integer
---@param opts ever.UiRenderOpts
function M.set_lines(bufnr, opts)
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end
    local run_cmd = require("ever._core.run_cmd").run_cmd
    local start_line = opts.start_line or 0
    vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
    local stat_line = run_cmd(
        "git diff --staged --shortstat | grep -q '^' && git diff --staged --shortstat || echo 'No files staged'"
    )[1]
    local files = run_cmd("git status --porcelain --untracked")
    M._sort_status_files(files)
    vim.api.nvim_buf_set_lines(bufnr, math.max(0, start_line - 1), -1, false, { stat_line, unpack(files) })
    vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
    highlight(bufnr, start_line, files)
end

---@param bufnr integer
---@param line_num? integer
---@return ever.StatusLineData | nil
function M.get_line(bufnr, line_num)
    line_num = line_num or vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1]
    if line == "" then
        return nil
    end
    if not line:match("^%s?[%w%?]") then
        return nil
    end
    local filename = line:sub(4)
    return { filename = filename, safe_filename = "'" .. filename .. "'", status = get_status(line) }
end

---@param bufnr integer
---@param opts ever.UiRenderOpts
function M.set_keymaps(bufnr, opts)
    local default_ui_keymap_opts = { auto_display_keymaps = true }
    local ui_keymap_opts = vim.tbl_extend("force", default_ui_keymap_opts, opts.keymap_opts or {})
    local keymaps = require("ever._ui.keymaps.base").get_keymaps(bufnr, "status", ui_keymap_opts)
    local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }
    local set = require("ever._ui.keymaps.set").safe_set_keymap

    set("n", keymaps.stage, function()
        local line_data = M.get_line(bufnr)
        if not line_data then
            return
        end
        local result
        if not require("ever._core.git").is_staged(line_data.status) then
            result =
                require("ever._core.run_cmd").run_hidden_cmd("git add -- " .. line_data.filename, { rerender = true })
        else
            result = require("ever._core.run_cmd").run_hidden_cmd(
                "git reset HEAD -- " .. line_data.filename,
                { rerender = true }
            )
        end
        if result == "error" then
            return
        end
    end, keymap_opts)

    set("v", keymaps.stage, function()
        local start_line, end_line = require("ever._ui.utils.ui_utils").get_visual_line_nums()
        start_line = math.max(start_line, opts.start_line or 0)
        local files = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line, false)
        local should_stage = require("ever._ui.home_options.status.status_utils").should_stage_files(files)
        local files_as_string = ""
        for i, file in ipairs(files) do
            -- dont' add space for first file, and don't include status
            files_as_string = files_as_string .. (i == 0 and "" or " ") .. file:sub(4)
        end
        if should_stage then
            require("ever._core.run_cmd").run_hidden_cmd("git add " .. files_as_string, { rerender = true })
            return
        end
        require("ever._core.run_cmd").run_hidden_cmd("git restore --staged -- " .. files_as_string, { rerender = true })
    end, keymap_opts)

    set("n", keymaps.stage_all, function()
        local should_stage = require("ever._ui.home_options.status.status_utils").should_stage_files(
            vim.api.nvim_buf_get_lines(bufnr, opts.start_line or 0, -1, false)
        )
        if should_stage then
            require("ever._core.run_cmd").run_hidden_cmd("git add -A", { rerender = true })
            return
        end
        require("ever._core.run_cmd").run_hidden_cmd("git reset", { rerender = true })
    end, keymap_opts)

    local keymap_to_command_map = {
        { keymap = keymaps.pull, command = "pull" },
        { keymap = keymaps.push, command = "push" },
    }

    for _, mapping in ipairs(keymap_to_command_map) do
        set("n", mapping.keymap, function()
            vim.cmd("G " .. mapping.command)
        end, keymap_opts)
    end

    set("n", keymaps.commit_popup, require("ever._ui.popups.plug_mappings").MAPPINGS.EVER_COMMIT_POPUP, keymap_opts)

    set("n", keymaps.diff_file, function()
        local line_data = M.get_line(bufnr)
        if not line_data then
            return
        end
        vim.api.nvim_exec2("G diff " .. line_data.filename, {})
    end, keymap_opts)

    set("n", keymaps.edit_file, function()
        local line_data = M.get_line(bufnr)
        if not line_data then
            return
        end
        vim.api.nvim_exec2("e " .. line_data.filename, {})
    end, keymap_opts)

    set("n", keymaps.enter_staging_area, function()
        vim.cmd("G difftool")
    end, keymap_opts)

    set("n", keymaps.restore, function()
        local line_data = M.get_line(bufnr)
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
                if not selection then
                    return
                end
                if selection == "Just this file" then
                    if not filename then
                        return
                    end
                    if status_checks.is_untracked(status) then
                        cmd = "git clean -f " .. filename
                    elseif status_checks.is_staged(status) then
                        cmd = "git reset -- " .. filename .. " && git clean -f -- " .. filename
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
                require("ever._core.run_cmd").run_hidden_cmd(cmd, { rerender = true })
            end
        )
    end, keymap_opts)

    set("n", keymaps.stash_popup, require("ever._ui.popups.plug_mappings").MAPPINGS.EVER_STASH_POPUP, keymap_opts)
end

--- Worth noting we don't include "git" in the string
---@param status string
---@param filename string
---@return string
local function get_diff_cmd(status, filename)
    local status_checks = require("ever._core.git")
    if status_checks.is_untracked(status) then
        return "diff --no-index /dev/null -- " .. filename
    end
    if status_checks.is_deleted(status) then
        if status_checks.is_staged(status) then
            return "diff --cached -- " .. filename
        end
        return "diff -- " .. filename
    end
    if status_checks.is_staged(status) then
        return "diff --staged -- " .. filename
    end
    return "diff -- " .. filename
end

---@param bufnr integer
---@param opts ever.UiRenderOpts
function M.render(bufnr, opts)
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end
    if opts.start_line then
        opts.start_line = opts.start_line + 1
    end
    M.set_lines(bufnr, opts)
    require("ever._ui.auto_display").create_auto_display(bufnr, "status", {
        generate_cmd = function()
            local line_data = M.get_line(bufnr)
            if not line_data then
                return
            end
            return get_diff_cmd(line_data.status, line_data.safe_filename)
        end,
        get_current_diff = function()
            local line_data = M.get_line(bufnr)
            if not line_data then
                return
            end
            return line_data.safe_filename
        end,
        strategy = { enter = false },
    })
    M.set_keymaps(bufnr, opts)
end

return M
