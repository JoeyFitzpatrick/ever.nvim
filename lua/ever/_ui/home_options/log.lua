-- Log rendering

local M = {}

--- Highlight log (commit) lines
---@param bufnr integer
---@param start_line integer
---@param lines string[]
local function highlight(bufnr, start_line, lines)
    local highlight_line = require("ever._ui.highlight").highlight_line
    for i, line in ipairs(lines) do
        local line_num = i + start_line - 1
        local hash_start, hash_end = line:find("^󰜘 %w+")
        highlight_line(bufnr, "MatchParen", line_num, hash_start, hash_end)
        local date_start, date_end = line:find(".+ago", hash_end + 1)
        highlight_line(bufnr, "Function", line_num, date_start, date_end)
        local author_start, author_end = line:find("%s%s+(.-)%s%s+", date_end + 1)
        highlight_line(bufnr, "Identifier", line_num, author_start, author_end)
    end
end

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

---@param bufnr integer
---@param opts ever.UiRenderOpts
---@return string[]
local function set_lines(bufnr, opts)
    local start_line = opts.start_line or 0
    local output = require("ever._core.run_cmd").run_cmd({
        "git",
        "log",
        "--pretty=format:󰜘 %h %<(25)%cr %<(25)%an %<(25)%s",
    })
    vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
    vim.api.nvim_buf_set_lines(bufnr, start_line, -1, false, output)
    vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
    highlight(bufnr, start_line, output)
    return output
end

---@param bufnr integer
---@param opts ever.UiRenderOpts
local function set_keymaps(bufnr, opts)
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
            require("ever._core.run_cmd").run_hidden_cmd({ "git", "reset", "--" .. selection, line_data.hash })
            set_lines(bufnr, opts)
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
---@param opts ever.UiRenderOpts
function M.render(bufnr, opts)
    set_lines(bufnr, opts)
    set_keymaps(bufnr, opts)
end

return M
