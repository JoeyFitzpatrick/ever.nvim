local log = require("ever._vendors.gitgraph.log")
local config = require("ever._vendors.gitgraph.config")
local highlights = require("ever._vendors.gitgraph.highlights")

local M = {
    config = config.defaults,

    buf = nil, ---@type integer?
    graph = {}, ---@type I.Row[]
}

--- Setup
---@param user_config I.GGConfig
function M.setup(user_config)
    M.config = vim.tbl_deep_extend("force", M.config, user_config)

    highlights.set_highlights()

    math.randomseed(os.time())

    log.set_level(M.config.log_level)
end

--- Draws the gitgraph in buffer
---@param bufnr integer
---@param options I.DrawOptions
---@param args I.GitLogArgs
---@return nil
function M.draw(bufnr, options, args)
    return require("ever._vendors.gitgraph.draw").draw(bufnr, M.config, options, args)
end

--- Tests the gitgraph plugin
function M.test()
    local lines, _ = require("ever._vendors.gitgraph.tests").run_tests(M.config.symbols, M.config.format.fields)

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, buf)

    vim.api.nvim_buf_set_lines(buf, 0, #lines, false, lines)

    local cursor_line = #lines
    vim.api.nvim_win_set_cursor(0, { cursor_line, 0 })
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

--- Draws a random gitgraph
function M.random()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, buf)

    local lines = require("ever._vendors.gitgraph.tests").run_random(M.config.symbols, M.config.format.fields)

    vim.api.nvim_buf_set_lines(buf, 0, #lines, false, lines)

    local cursor_line = 1
    vim.api.nvim_win_set_cursor(0, { cursor_line, 0 })
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

return M
