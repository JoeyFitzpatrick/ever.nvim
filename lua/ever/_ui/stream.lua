---@class ever.StreamLinesOpts
---@field error_code_handlers? table<integer, function>
---@field transform_line? fun(line: string): string
---@field highlight_line? fun(bufnr: integer, line: string, line_num: integer)
---@field on_exit? fun(bufnr: integer)
---@field filetype? string
---@field filter_empty_lines? boolean

local M = {}

---@param bufnr integer
---@param cmd string
---@param opts ever.StreamLinesOpts
function M.stream_lines(bufnr, cmd, opts)
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end
    if opts.filetype then
        vim.api.nvim_set_option_value("filetype", opts.filetype, { buf = bufnr })
    end
    local line_num = 0
    local error_code_handlers = opts.error_code_handlers or {}
    local function on_stdout(_, data, _)
        if data then
            -- Populate the buffer with the incoming lines
            vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
            for _, line in ipairs(data) do
                if opts.transform_line then
                    line = opts.transform_line(line)
                end
                local should_filter_line = opts.filter_empty_lines and line == ""
                if not should_filter_line then
                    vim.api.nvim_buf_set_lines(bufnr, line_num, line_num + 1, false, { line })
                    if opts.highlight_line then
                        pcall(opts.highlight_line, bufnr, line, line_num)
                    end
                end
                line_num = line_num + 1
            end
            vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
        end
    end

    local function on_exit(code)
        if opts.filetype then
            vim.api.nvim_set_option_value("filetype", opts.filetype, { buf = bufnr })
        end
        vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
        if code ~= 0 then
            vim.notify("command '" .. cmd .. "' failed with exit code " .. code, vim.log.levels.ERROR)
        end
        if opts.on_exit then
            opts.on_exit(bufnr)
        end
    end

    -- Remove existing lines before adding new lines
    -- This is for when we rerender the output
    vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
    -- vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
    -- Start the asynchronous job
    vim.fn.jobstart(cmd, {
        on_stdout = function(...)
            pcall(on_stdout, ...)
        end,
        -- on_stderr = function(code, output, _)
        --     if not error_code_handlers[code] then
        --         -- Handle stderr the same way for simplicity
        --         pcall(on_stdout, code, output)
        --     end
        -- end,
        on_exit = function(_, code, _)
            if not error_code_handlers[code] then
                pcall(on_exit, code)
            else
                error_code_handlers[code]()
            end
        end,
    })
end

return M
