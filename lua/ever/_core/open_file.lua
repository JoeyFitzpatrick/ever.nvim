local M = {}

---@param filename string
---@param commit string
local function get_filename(filename, commit)
    return commit .. "--" .. filename
end

---@param name string
local function delete_existing_buffer(name)
    vim.print("current name: " .. name)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local buf_name = vim.api.nvim_buf_get_name(buf)
        if buf_name:find(name, 1, true) then
            vim.api.nvim_buf_delete(buf, { force = true })
            return
        end
    end
end

--- This function assumes that we've already checked to see if there's
--- an open buffer for this file/commit.
---@param bufnr integer
---@param filename string
---@param commit string
local function setup_git_file(bufnr, filename, commit)
    local lines = require("ever._core.run_cmd").run_cmd(
        string.format("git show %s:%s", commit, require("ever._core.texter").surround_with_quotes(filename))
    )
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
    local commit_filename = get_filename(filename, commit)
    vim.api.nvim_buf_set_name(bufnr, commit_filename)
    vim.api.nvim_set_option_value("filetype", vim.filetype.match({ buf = bufnr }), { buf = bufnr })

    vim.keymap.set("n", "q", function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end, { buffer = bufnr })
end

---@param filename string
---@param commit string
---@param split "above" | "below" | "right" | "left"
function M.open_file_in_split(filename, commit, split)
    delete_existing_buffer(get_filename(filename, commit))
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_open_win(bufnr, true, { split = split })
    setup_git_file(bufnr, filename, commit)
end

---@param filename string
---@param commit string
function M.open_file_in_tab(filename, commit)
    vim.cmd("tabnew")
    delete_existing_buffer(get_filename(filename, commit))
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, bufnr)
    setup_git_file(bufnr, filename, commit)
end

---@param filename string
---@param commit string
function M.open_file_in_current_window(filename, commit)
    delete_existing_buffer(get_filename(filename, commit))
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, bufnr)
    setup_git_file(bufnr, filename, commit)
end

return M
