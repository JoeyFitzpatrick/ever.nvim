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
    opts = opts or {}
    local start_line = opts.start_line or 0
    local output = require("ever._core.run_cmd").run_cmd({ "git", "status", "--porcelain" })
    vim.api.nvim_buf_set_lines(bufnr, start_line or 0, -1, false, output)
    return output
end

---@param bufnr integer
---@param line_num? integer
---@return { line: string, status: string }
local function get_line(bufnr, line_num)
    line_num = line_num or vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1]
    return { line = line:sub(4), status = get_status(line) }
end

---@param bufnr integer
---@param opts ever.UiRenderOpts
local function set_keymaps(bufnr, opts)
    local keymaps = require("ever._core.configuration").DATA.keymaps.status

    vim.keymap.set("n", keymaps.stage, function()
        local line_data = get_line(bufnr)
        if not require("ever._core.git").is_staged(line_data.status) then
            vim.system({ "git", "add", "--", line_data.line }):wait()
        else
            vim.system({ "git", "reset", "HEAD", "--", line_data.line }):wait()
        end
        local output = set_lines(bufnr, opts)
        highlight(bufnr, opts.start_line or 0, output)
    end, { buffer = bufnr, nowait = true })

    vim.keymap.set("n", keymaps.stage_all, function()
        for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, opts.start_line or 0, -1, false)) do
            if line:match("^.%S") then
                vim.system({ "git", "add", "-A" }):wait()
                                goto continue
            end
        end
        vim.system({ "git", "reset" }):wait()
                ::continue::
        local output = set_lines(bufnr, opts)
        highlight(bufnr, opts.start_line or 0, output)
    end, { buffer = bufnr, nowait = true })
end

---@param bufnr integer
---@param opts ever.UiRenderOpts
function M.render(bufnr, opts)
    local output = set_lines(bufnr, opts)
    local start_line = opts.start_line or 0
    highlight(bufnr, start_line, output)
    set_keymaps(bufnr, opts)
end

return M
