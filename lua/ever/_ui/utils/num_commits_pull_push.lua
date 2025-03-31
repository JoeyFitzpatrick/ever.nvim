local M = {}

---@param branch string
local function get_num_commits_to_pull_and_push(branch)
    local run_cmd = require("ever._core.run_cmd").run_cmd
    local pull_lines, pull_error_code = run_cmd(string.format("git rev-list --count %s..origin/%s", branch, branch))
    local push_lines, push_error_code = run_cmd(string.format("git rev-list --count origin/%s..%s", branch, branch))
    if pull_error_code ~= 0 or push_error_code ~= 0 then
        return ""
    end
    local pull, push = pull_lines[1], push_lines[1]
    local pull_and_push = ""
    if pull ~= "0" then
        pull_and_push = pull_and_push .. "↓" .. pull
    end
    if push ~= "0" then
        if pull_and_push ~= "" then
            pull_and_push = pull_and_push .. " "
        end
        pull_and_push = pull_and_push .. "↑" .. push
    end
    return pull_and_push
end

---@param bufnr integer
---@param highlight fun(bufnr: integer, start_line: integer, lines: string[])
---@param start_line? integer
local function render_num_commits(bufnr, highlight, start_line)
    local new_output = {}
    if start_line == nil then
        start_line = 0
    end
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end
    for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, start_line, -1, false)) do
        local line_without_num_commits = line:match("..%S*")
        local branch = line:match("%a%S*")
        if branch and line_without_num_commits then
            table.insert(new_output, line_without_num_commits .. " " .. get_num_commits_to_pull_and_push(branch))
        end
    end
    vim.bo[bufnr].modifiable = true
    vim.api.nvim_buf_set_lines(bufnr, start_line, -1, false, new_output)
    vim.bo[bufnr].modifiable = false
    highlight(bufnr, start_line, new_output)
end

---@param bufnr integer
---@param highlight fun(bufnr: integer, start_line: integer, lines: string[])
---@param start_line? integer
function M.set_num_commits_to_pull_and_push(bufnr, highlight, start_line)
    render_num_commits(bufnr, highlight, start_line)
    vim.fn.jobstart("git fetch", {
        on_exit = function(_, code, _)
            if code ~= 0 then
                return
            end
            render_num_commits(bufnr, highlight, start_line)
        end,
    })
end

return M
