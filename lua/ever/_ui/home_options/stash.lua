local M = {}

--- Highlight stash lines
---@param bufnr integer
---@param start_line integer
---@param lines string[]
local function highlight(bufnr, start_line, lines)
    local highlight_line = require("ever._ui.highlight").highlight_line
    for i, line in ipairs(lines) do
        if line == "" then
            return
        end
        local line_num = i + start_line - 1
        local stash_index_start, stash_index_end = line:find("^%S+")
        highlight_line(bufnr, "Keyword", line_num, stash_index_start, stash_index_end)
        local date_start, date_end = line:find(".+ago", stash_index_end + 1)
        highlight_line(bufnr, "Function", line_num, date_start, date_end)
        local branch_start, branch_end = line:find(" .+:", date_end + 1)
        highlight_line(bufnr, "Removed", line_num, branch_start, branch_end)
    end
end

---@param bufnr integer
---@param opts ever.UiRenderOpts
---@return string[]
local function set_lines(bufnr, opts)
    local start_line = opts.start_line or 0
    local output =
        require("ever._core.run_cmd").run_cmd("git stash list --pretty=format:'%<(12)%gd %<(18)%cr   %<(25)%s'")
    vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
    vim.api.nvim_buf_set_lines(bufnr, start_line, -1, false, output)
    vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
    highlight(bufnr, start_line, output)
    return output
end

---@param bufnr integer
---@param line_num? integer
---@return { stash_index: string } | nil
local function get_line(bufnr, line_num)
    line_num = line_num or vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1]
    if line == "" then
        return nil
    end
    return { stash_index = line:match(".+}") }
end

---@param bufnr integer
local function set_keymaps(bufnr)
    local keymaps = require("ever._ui.keymaps.base").get_ui_keymaps(bufnr, "stash")
    local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }

    vim.keymap.set("n", keymaps.apply, function()
        local line_data = get_line(bufnr)
        if not line_data then
            return
        end
        vim.cmd("G stash apply " .. line_data.stash_index)
    end, keymap_opts)

    vim.keymap.set("n", keymaps.drop, function()
        local line_data = get_line(bufnr)
        if not line_data then
            return
        end
        vim.ui.select(
            { "No", "Yes" },
            { prompt = "Are you sure you want to drop " .. line_data.stash_index .. "? " },
            function(selection)
                if selection == "Yes" then
                    vim.cmd("G stash drop " .. line_data.stash_index)
                end
            end
        )
    end, keymap_opts)

    vim.keymap.set("n", keymaps.pop, function()
        local line_data = get_line(bufnr)
        if not line_data then
            return
        end
        vim.cmd("G stash pop " .. line_data.stash_index)
    end, keymap_opts)
end

---@param bufnr integer
---@param opts ever.UiRenderOpts
function M.render(bufnr, opts)
    set_lines(bufnr, opts)
    set_keymaps(bufnr)
end

function M.cleanup(bufnr)
    require("ever._core.register").deregister_buffer(bufnr)
end

return M
