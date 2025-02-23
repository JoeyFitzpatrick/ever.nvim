local M = {}

local function set_keymaps(bufnr)
    local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }

    vim.keymap.set("n", "q", function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end, keymap_opts)
end

---@param bufnr integer
---@param cmd string
local function stream_lines(bufnr, cmd)
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

    local function on_exit(_, code, _)
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
        -- Handle stderr the same way for simplicity
        on_stderr = function(...)
            pcall(on_stdout, ...)
        end,
        on_exit = function(...)
            pcall(on_exit, ...)
        end,
    })
end

---@param cmd string
M.render = function(cmd)
    if not cmd:match("^git ") then
        cmd = "git " .. cmd
    end
    local bufnr = require("ever._ui.elements").new_buffer({ filetype = "git" })
    set_keymaps(bufnr)
    stream_lines(bufnr, cmd)
end

return M
