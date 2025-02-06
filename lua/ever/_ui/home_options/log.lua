-- Log rendering

local M = {}

---@param bufnr integer
---@param line string
---@param line_num integer
local function highlight_line(bufnr, line, line_num)
    local ui_highlight_line = require("ever._ui.highlight").highlight_line
    if not line or line == "" then
        return
    end
    local hash_start, hash_end = line:find("^󰜘 %w+")
    ui_highlight_line(bufnr, "MatchParen", line_num, hash_start, hash_end)
    local date_start, date_end = line:find(".+ago", hash_end + 1)
    ui_highlight_line(bufnr, "Function", line_num, date_start, date_end)
    local author_start, author_end = line:find("%s%s+(.-)%s%s+", date_end + 1)
    ui_highlight_line(bufnr, "Identifier", line_num, author_start, author_end)
end

--- --- Highlight log (commit) lines
--- ---@param bufnr integer
--- ---@param start_line integer
--- ---@param lines string[]
--- local function highlight(bufnr, start_line, lines)
-- local highlight_line = require("ever._ui.highlight").highlight_line
---     for i, line in ipairs(lines) do
---         if line == "" then
---             return
---         end
---         local line_num = i + start_line - 1
---         local hash_start, hash_end = line:find("^󰜘 %w+")
---         highlight_line(bufnr, "MatchParen", line_num, hash_start, hash_end)
---         local date_start, date_end = line:find(".+ago", hash_end + 1)
---         highlight_line(bufnr, "Function", line_num, date_start, date_end)
---         local author_start, author_end = line:find("%s%s+(.-)%s%s+", date_end + 1)
---         highlight_line(bufnr, "Identifier", line_num, author_start, author_end)
---     end
--- end

---@param bufnr integer
---@param line_num? integer
---@return { hash: string } | nil
local function get_line(bufnr, line_num)
    line_num = line_num or vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1]
    if line == "" then
        return nil
    end
    return { hash = line:match("%w+", 4) }
end

--- This `set_lines` is different than the others, in that it streams content into the buffer
--- instead of writing it all at once.
---@param bufnr integer
---@return string[]
local function set_lines(bufnr)
    local function on_stdout(_, data, _)
        if data then
            -- Populate the buffer with the git log data
            vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
            for _, line in ipairs(data) do
                if line ~= "" then
                    vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, { line })
                    highlight_line(bufnr, line, vim.api.nvim_buf_line_count(bufnr) - 1)
                end
            end
            vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
        end
    end

    local function on_exit(_, code, _)
        vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
        if code ~= 0 then
            vim.notify("git log command failed with exit code " .. code, vim.log.levels.ERROR)
        end
    end

    -- Start the asynchronous job
    vim.fn.jobstart({ "git", "log", "--pretty=format:󰜘 %h %<(25)%cr %<(25)%an %<(25)%s" }, {
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
    -- highlight(bufnr, start_line, output)
    -- return output
end

---@param bufnr integer
local function set_keymaps(bufnr)
    local keymaps = require("ever._core.configuration").DATA.keymaps.log
    local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }

    vim.keymap.set("n", keymaps.commit_info, function()
        local line_data = get_line(bufnr)
        if not line_data then
            return
        end
        require("ever._ui.elements").float(
            vim.api.nvim_create_buf(false, true),
            { title = "Git log " .. line_data.hash }
        )
        require("ever._ui.elements").terminal("log -n 1 " .. line_data.hash, { display_strategy = "full" })
    end, keymap_opts)

    vim.keymap.set("n", keymaps.reset, function()
        local line_data = get_line(bufnr)
        if not line_data then
            return
        end
        vim.ui.select({ "mixed", "soft", "hard" }, { prompt = "Git reset type: " }, function(selection)
            require("ever._core.run_cmd").run_hidden_cmd("git reset --" .. selection .. " " .. line_data.hash)
            set_lines(bufnr)
        end)
    end, keymap_opts)

    vim.keymap.set("n", keymaps.revert, function()
        local line_data = get_line(bufnr)
        if not line_data then
            return
        end
        vim.cmd("G revert " .. line_data.hash .. " --no-commit")
    end, keymap_opts)

    vim.keymap.set("n", keymaps.show, function()
        local line_data = get_line(bufnr)
        if not line_data then
            return
        end
        require("ever._ui.elements").float(
            vim.api.nvim_create_buf(false, true),
            { title = "Git show " .. line_data.hash }
        )
        require("ever._ui.elements").terminal("show " .. line_data.hash, { display_strategy = "full", insert = true })
    end, keymap_opts)
end

---@param bufnr integer
function M.render(bufnr)
    set_lines(bufnr)
    set_keymaps(bufnr)
end

function M.cleanup(bufnr)
    require("ever._core.register").deregister_buffer(bufnr)
end

return M
