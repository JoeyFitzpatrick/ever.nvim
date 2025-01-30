---@alias ElementType "terminal" | "home"

local M = {}

--- Some commands parse command options to determine what display strat to use. In this case, run the parse function, otherwise return the display strat.
---@param cmd string[]
---@param display_strategy ever.DisplayStrategy | ever.DisplayStrategyParser
---@return ever.DisplayStrategy
local function parse_display_strategy(cmd, display_strategy)
    if type(display_strategy) == "function" then
        return display_strategy(cmd)
    end
    return display_strategy
end

--- Some commands parse command options to determine whether to enter in insert mode. In this case, run the parse function, otherwise return the bool.
---@param cmd string[]
---@param should_enter_insert boolean | ever.ShouldEnterInsert
---@return boolean
local function parse_should_enter_insert(cmd, should_enter_insert)
    if type(should_enter_insert) == "function" then
        return should_enter_insert(cmd)
    end
    return should_enter_insert
end

--- Get the number of lines to trim in terminal output.
--- Empty lines at the end of the terminal output, and lines that begin with `[Process exited`, should be trimmed.
---@param lines string[]
---@return integer
M._get_num_lines_to_trim = function(lines)
    local num_lines_to_trim = 0
    for i = #lines, 1, -1 do
        if lines[i] == "" or lines[i]:find("[Process exited", 1, true) ~= nil then
            num_lines_to_trim = num_lines_to_trim + 1
        else
            break
        end
    end
    return num_lines_to_trim
end

---@param cmd string
---@param bufnr integer
---@param win integer
---@param strategy ever.Strategy
---@return integer -- The channel id of the terminal.
local function open_dynamic_terminal(cmd, bufnr, win, strategy)
    local height = 2
    local max_height = math.floor(vim.o.lines * 0.5)
    vim.api.nvim_win_set_height(win, height)
    local channel_id = vim.fn.jobstart(cmd, {
        term = true,
        on_stdout = function()
            local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
            local empty_lines = vim.tbl_filter(function(line)
                return line == ""
            end, lines)
            if #lines - #empty_lines + 1 > height then
                height = #lines - #empty_lines + 1
            end
            vim.api.nvim_win_set_height(win, math.min(height, max_height))
        end,
        on_exit = function()
            if strategy.trigger_redraw then
                require("ever._core.register").rerender_buffers()
            end
            local trim_terminal_output = function()
                local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
                local num_lines_to_trim = M._get_num_lines_to_trim(lines)
                vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
                vim.api.nvim_buf_set_lines(bufnr, -num_lines_to_trim, -1, false, {})
                vim.api.nvim_win_set_height(win, math.min(#lines - (num_lines_to_trim - 1), max_height))
                vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
            end
            -- Sometimes this function runs before "[Process exited 0]" is in the buffer, and it doesn't get removed.
            -- A small pause here ensures that it gets cleaned up consistently. We might need to adjust the time though.
            vim.defer_fn(function()
                pcall(trim_terminal_output)
            end, 100)
        end,
    })
    return channel_id
end

---@param cmd string
---@param split_cmd string[]
---@param bufnr integer
---@param strategy ever.Strategy
---@return integer -- The channel id of the terminal
local function open_terminal_buffer(cmd, split_cmd, bufnr, strategy)
    local strategies = require("ever._constants.command_strategies").STRATEGIES
    local display_strategy = parse_display_strategy(split_cmd, strategy.display_strategy)
    if vim.tbl_contains({ "above", "below", "right", "left" }, display_strategy) then
        vim.api.nvim_open_win(bufnr, true, { split = display_strategy })
    elseif display_strategy == strategies.FULL then
        vim.api.nvim_win_set_buf(0, bufnr)
    elseif display_strategy == strategies.DYNAMIC then
        local win = vim.api.nvim_open_win(bufnr, true, { split = "below" })
        return open_dynamic_terminal(cmd, bufnr, win, strategy)
    else
        error("Unable to determine display strategy", vim.log.levels.ERROR)
    end
    local channel_id = vim.fn.jobstart(cmd, { term = true })
    if strategy.trigger_redraw then
        require("ever._core.register").rerender_buffers()
    end
    return channel_id
end

--- Note that commands passed to this function should not be prefixed with "git", as it will be added.
---@param cmd string
---@param strategy? ever.Strategy
---@return integer -- The channel id of the terminal.
function M.terminal(cmd, strategy)
    cmd = "git " .. cmd
    local split_cmd = vim.split(cmd, " ")
    local bufnr = vim.api.nvim_create_buf(false, true)
    local base_cmd = split_cmd[2]
    local derived_strategy = require("ever._constants.command_strategies")[base_cmd]
    local base_strategy = require("ever._constants.command_strategies").default
    strategy = vim.tbl_extend("force", base_strategy, derived_strategy, strategy or {})
    local channel_id = open_terminal_buffer(cmd, split_cmd, bufnr, strategy)
    local should_enter_insert = parse_should_enter_insert(split_cmd, strategy.insert)
    if should_enter_insert then
        vim.cmd("startinsert")
    else
        vim.cmd("stopinsert")
    end
    require("ever._ui.keymaps.base").set_keymaps(bufnr, "terminal")
    return channel_id
end

---@param bufnr integer
---@param float_opts? vim.api.keyset.win_config
---@return integer -- win id
function M.float(bufnr, float_opts)
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.8)
    local col = math.floor((vim.o.columns - width) / 2)
    local row = math.floor((vim.o.lines - height) / 2)

    ---@type vim.api.keyset.win_config
    local default_float_opts = {
        relative = "editor",
        width = width,
        height = height,
        col = col,
        row = row,
        style = "minimal",
        border = "rounded",
    }
    float_opts = vim.tbl_extend("force", default_float_opts, float_opts or {})
    local win = vim.api.nvim_open_win(bufnr, true, float_opts)
    return win
end

return M
