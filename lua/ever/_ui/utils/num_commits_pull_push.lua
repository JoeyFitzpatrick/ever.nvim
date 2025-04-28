---@class ever.SetNumCommitsParams
---@field highlight fun(bufnr: integer, start_line: integer, lines: string[])
---@field start_line? integer
---@field end_line? integer
---@field line_type "branch" | "head"

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

--- This matches any valid branch characters, which are
--- anything except arrows (e.g. ↓↑). This is to match
--- either a branch, or text like
--- `(no branch, rebasing <branch-name>)`.
--- Matches up to, but not inluding, a final
--- whitespace character.
---@param line string
function M._get_line_without_num_commits(line)
    return line:match("[^↓↑]+[^↓↑%s]")
end

---@param bufnr integer
---@param opts ever.SetNumCommitsParams
local function render_num_commits(bufnr, opts)
    local start_line = opts.start_line
    local end_line = opts.end_line
    local new_output = {}

    if start_line == nil then
        start_line = 0
    end
    if end_line == nil then
        end_line = -1
    end

    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end
    for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, start_line, end_line, false)) do
        local line_without_num_commits = M._get_line_without_num_commits(line)
        local branch
        if opts.line_type == "branch" then
            branch = line:match("%a%S*")
        else
            -- For a line like "HEAD: main", the 7th char is "m"
            branch = line:match("%S+", 7)
        end
        if branch and line_without_num_commits then
            table.insert(new_output, line_without_num_commits .. " " .. get_num_commits_to_pull_and_push(branch))
        end
    end
    vim.bo[bufnr].modifiable = true
    vim.api.nvim_buf_set_lines(bufnr, start_line, end_line, false, new_output)
    vim.bo[bufnr].modifiable = false
    opts.highlight(bufnr, start_line, new_output)
end

--- This function is `vim.schedule_wrap`ped, so that it doesn't
--- block the main thread. Otherwise it causes sluggishness.
---@param bufnr integer
---@param opts ever.SetNumCommitsParams
M.set_num_commits_to_pull_and_push = vim.schedule_wrap(function(bufnr, opts)
    render_num_commits(bufnr, opts)
    local received_output = false
    vim.fn.jobstart("git fetch", {
        on_stdout = function(_, data, _)
            for _, line in ipairs(data) do
                if line and line ~= "" then
                    received_output = true
                    return
                end
            end
        end,
        on_stderr = function(_, data, _)
            for _, line in ipairs(data) do
                if line and line ~= "" then
                    received_output = true
                    return
                end
            end
        end,
        on_exit = function(_, code, _)
            if code ~= 0 or not received_output then
                return
            end
            render_num_commits(bufnr, opts)
        end,
    })
end)

---@param bufnr integer
---@param start_line integer
---@param lines string[]
function M.highlight_num_commits(bufnr, start_line, lines)
    for i, line in ipairs(lines) do
        local line_num = i + start_line - 1
        local pull_start, pull_end = line:find("↓%d+")
        require("ever._ui.highlight").highlight_line(bufnr, "Keyword", line_num, pull_start, pull_end)
        local push_start, push_end = line:find("↑%d+")
        require("ever._ui.highlight").highlight_line(bufnr, "Keyword", line_num, push_start, push_end)
    end
end

return M
