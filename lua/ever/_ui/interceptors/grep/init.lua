---@class ever.GrepQflistItem
---@field bufnr integer
---@field lnum integer
---@field col integer

---@class ever.GrepParsedOutput
---@field filename string
---@field commit string

local M = {}

---@param cmd string
local function add_grep_flags(cmd)
    return "git grep -n --column " .. cmd:gsub(".*grep%s", "")
end

---@param bufnr integer
---@param line string
---@return ever.GrepQflistItem
function M._create_grep_qflist_item(bufnr, line)
    local first_colon = line:find(":")
    local second_colon = line:find(":", first_colon + 1)
    local third_colon = line:find(":", second_colon + 1)
    return {
        bufnr = bufnr,
        lnum = tonumber(line:match("%d+", second_colon + 1)),
        col = tonumber(line:match("%d+", third_colon + 1)),
    }
end

---@param line string
---@return ever.GrepParsedOutput
local function parse_grep_output_line(line)
    local first_colon = line:find(":", 1, true)
    local commit = line:sub(1, first_colon - 1)
    local second_colon = line:find(":", first_colon + 1, true)
    local filename = line:sub(first_colon + 1, second_colon - 1)
    return { commit = commit, filename = filename }
end

---@param line string
local function create_qflist_item_buffer(line)
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, line:match(".+:"))
    return bufnr
end

---@param cmd string
function M.render(cmd)
    cmd = add_grep_flags(cmd)
    local buffer_render_fns = {}
    -- Action should be nil at first to create new qflist
    local action = " "
    local function on_stdout(_, data, _)
        if data then
            for _, line in ipairs(data) do
                local bufnr = create_qflist_item_buffer(line)
                local parsed_grep_output_line = parse_grep_output_line(line)
                buffer_render_fns[bufnr] = vim.schedule_wrap(function()
                    local lines = require("ever._core.run_cmd").run_cmd(
                        string.format(
                            "git show %s -- %s",
                            parsed_grep_output_line.commit,
                            parsed_grep_output_line.filename
                        )
                    )
                    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
                end)
                vim.fn.setqflist({ M._create_grep_qflist_item(bufnr, line) }, action)
                if action == " " then
                    action = "a"
                end
            end
        end
    end

    local function on_exit(code)
        if code ~= 0 then
            vim.notify("command '" .. cmd .. "' failed with exit code " .. code, vim.log.levels.ERROR)
        else
            vim.cmd("copen")
            vim.schedule(function()
                for _, render_fn in pairs(buffer_render_fns) do
                    render_fn()
                end
            end)
        end
    end

    -- Start the asynchronous job
    vim.fn.jobstart(cmd, {
        on_stdout = function(...)
            pcall(on_stdout, ...)
        end,
        on_exit = function(_, code, _)
            pcall(on_exit, code)
        end,
    })
end

return M
