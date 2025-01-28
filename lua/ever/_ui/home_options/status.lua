-- Status rendering

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
            highlight_group = highlight_groups.EVER_DIFF_DELETE
        end
        vim.api.nvim_buf_add_highlight(bufnr, -1, highlight_group, line_num + start_line - 1, 0, 2)
    end
end

---@param bufnr integer
---@param opts ever.UiRenderOpts
---@return string[]
local function set_lines(bufnr, opts)
    local start_line = opts.start_line or 0
    local output = require("ever._core.run_cmd").run_cmd({ "git", "status", "--porcelain" })
    vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
    vim.api.nvim_buf_set_lines(bufnr, start_line, -1, false, output)
    vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
    highlight(bufnr, start_line, output)
    return output
end

---@param bufnr integer
---@param line_num? integer
---@return { filename: string, status: string } | nil
local function get_line(bufnr, line_num)
    line_num = line_num or vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1]
    if line == "" then
        return nil
    end
    return { filename = line:sub(4), status = get_status(line) }
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
            result = require("ever._core.run_cmd").run_hidden_cmd({ "git", "add", "--", line_data.filename })
        else
            result = require("ever._core.run_cmd").run_hidden_cmd({ "git", "reset", "HEAD", "--", line_data.filename })
        end
        if result == "error" then
            return
        end
        set_lines(bufnr, opts)
    end, keymap_opts)

    vim.keymap.set("n", keymaps.stage_all, function()
        for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, opts.start_line or 0, -1, false)) do
            if line:match("^.%S") then
                require("ever._core.run_cmd").run_hidden_cmd({ "git", "add", "-A" })
                set_lines(bufnr, opts)
                return
            end
        end
        require("ever._core.run_cmd").run_hidden_cmd({ "git", "reset" })
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
            -- TODO: make this actually work
            set_lines(bufnr, opts)
        end, keymap_opts)
    end

    vim.keymap.set("n", keymaps.edit_file, function()
        local line_data = get_line(bufnr)
        if not line_data then
            return
        end
        vim.api.nvim_exec2("e " .. line_data.filename, {})
    end)
end

---@param bufnr integer
---@param opts ever.UiRenderOpts
function M.render(bufnr, opts)
    set_lines(bufnr, opts)
    set_keymaps(bufnr, opts)
end

return M
