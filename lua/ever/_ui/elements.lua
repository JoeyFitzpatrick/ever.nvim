---@alias ever.ElementType "terminal" | "home"

---@class ever.ElementNewBufferOpts
---@field filetype? string
---@field lines? fun(bufnr?: integer): string[]
---@field win_config? vim.api.keyset.win_config
---@field enter? boolean
---@field buffer_name? string

local M = {}

--- Some commands parse command options to determine what display strat to use.
--- In this case, run the parse function, otherwise return the display strat.
---@param cmd string[]
---@param display_strategy ever.DisplayStrategy | ever.DisplayStrategyParser
---@return ever.DisplayStrategy
local function parse_display_strategy(cmd, display_strategy)
    if type(display_strategy) == "function" then
        return display_strategy(cmd)
    end
    return display_strategy
end

--- Some commands parse command options to determine whether to enter in insert mode.
--- In this case, run the parse function, otherwise return the bool.
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

local function output_is_empty(bufnr)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local empty_lines = vim.tbl_filter(function(line)
        return line == ""
    end, lines)
    return #lines == #empty_lines
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
                if output_is_empty(bufnr) then
                    vim.api.nvim_buf_delete(bufnr, { force = true })
                end
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
    local win = vim.api.nvim_get_current_win()
    if vim.tbl_contains({ "above", "below", "right", "left" }, display_strategy) then
        local enter = true
        if strategy.enter == false then
            enter = false
        end
        -- Cast this to appease type checker
        ---@cast display_strategy "above" | "below" | "right" | "left"
        if strategy.win_size then
            if vim.tbl_contains({ "above", "below" }, display_strategy) then
                local height = math.floor(vim.o.lines * strategy.win_size)
                win = vim.api.nvim_open_win(bufnr, enter, { split = display_strategy, height = height })
            else
                local width = math.floor(vim.o.columns * strategy.win_size)
                win = vim.api.nvim_open_win(bufnr, enter, { split = display_strategy, width = width })
            end
        else
            win = vim.api.nvim_open_win(bufnr, enter, { split = display_strategy })
        end
    elseif display_strategy == strategies.FULL then
        vim.api.nvim_win_set_buf(0, bufnr)
    elseif display_strategy == strategies.DYNAMIC then
        win = vim.api.nvim_open_win(bufnr, true, { split = "below" })
        return open_dynamic_terminal(cmd, bufnr, win, strategy)
    else
        error("Unable to determine display strategy", vim.log.levels.ERROR)
    end
    local channel_id
    vim.api.nvim_win_call(win, function()
        channel_id = vim.fn.jobstart(cmd, {
            term = true,
            on_exit = function()
                if strategy.trigger_redraw then
                    require("ever._core.register").rerender_buffers()
                end
            end,
        })
        vim.opt_local.number = false
    end)
    return channel_id
end

---@param cmd string
---@param strategy? ever.Strategy
---@return integer, integer -- terminal channel id, buffer id
function M.terminal(cmd, strategy)
    local split_cmd = vim.split(cmd, " ")
    local bufnr = vim.api.nvim_create_buf(false, true)
    -- Buffer local variable that makes any editors opened from this terminal,
    -- such as the commit editor, use the current nvim instance instead of a nested one.
    vim.b[bufnr].ever_use_nested_nvim = true
    local base_cmd = split_cmd[2]
    local base_strategy = require("ever._constants.command_strategies").default
    local derived_strategy = require("ever._constants.command_strategies")[base_cmd] or {}
    strategy = vim.tbl_extend("force", base_strategy, derived_strategy, strategy or {})
    local channel_id = open_terminal_buffer(cmd, split_cmd, bufnr, strategy)
    local should_enter_insert = parse_should_enter_insert(split_cmd, strategy.insert)
    if should_enter_insert then
        vim.cmd("startinsert")
    else
        vim.cmd("stopinsert")
    end
    require("ever._ui.keymaps.base").set_keymaps(bufnr, { terminal_channel_id = channel_id })
    return channel_id, bufnr
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

--- This sets up buffer local variables, so that when an Ever buffer is closed,
--- we can navigate back to the last non-Ever buffer, and close all Ever
--- buffers associated with the current window.
---@param current_buf integer
---@param new_buf integer
---@param win integer
local function setup_last_non_ever_buffer(current_buf, new_buf, win)
    vim.b[new_buf].is_ever_buffer = true

    if not vim.b[current_buf].is_ever_buffer then
        require("ever._core.register").last_non_ever_buffer_for_win[win] = current_buf
    end
end

---@param opts ever.ElementNewBufferOpts -- opts for new buffer
---@return integer, integer -- buffer id, window id
function M.new_buffer(opts)
    local current_buf = vim.api.nvim_get_current_buf()
    local bufnr = vim.api.nvim_create_buf(false, true)

    local win
    if opts.win_config then
        local enter = true
        if opts.enter == false then
            enter = false
        end
        win = vim.api.nvim_open_win(bufnr, enter, opts.win_config)
    else
        win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(win, bufnr)
    end

    if opts.filetype then
        vim.api.nvim_set_option_value("filetype", opts.filetype, { buf = bufnr })
    end

    if opts.buffer_name then
        local ok = pcall(vim.api.nvim_buf_set_name, bufnr, opts.buffer_name)
        if not ok then
            vim.cmd("e " .. opts.buffer_name)
        else
            if opts.lines then
                vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, opts.lines(bufnr))
                vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
            end
        end
    end

    local register = require("ever._core.register")
    register.register_buffer(bufnr, { win = win })

    vim.keymap.set("n", "q", function()
        register.deregister_buffer(bufnr, {})
    end, { buffer = bufnr })

    setup_last_non_ever_buffer(current_buf, bufnr, win)

    return bufnr, win
end

return M
