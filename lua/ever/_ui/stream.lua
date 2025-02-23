---@alias ever.ErrorCodeHandlers table<integer, function>

local M = {}

---@param bufnr integer
---@param cmd string
---@param error_code_handlers ever.ErrorCodeHandlers
function M.stream_lines(bufnr, cmd, error_code_handlers)
    local function on_stdout(_, data, _)
        if data then
            -- Populate the buffer with the incoming lines
            vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
            for _, line in ipairs(data) do
                if line ~= "" then
                    vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, { line })
                end
            end
            vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
        end
    end

    local function on_exit(code)
        vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
        if code ~= 0 then
            vim.notify("command '" .. cmd .. "' failed with exit code " .. code, vim.log.levels.ERROR)
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
