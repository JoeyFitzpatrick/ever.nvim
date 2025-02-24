local M = {}

local function set_keymaps(bufnr)
    local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }

    vim.keymap.set("n", "q", function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end, keymap_opts)
end

local function highlight_line(bufnr, line, line_num)
    local hlgroups = require("ever._constants.highlight_groups").highlight_groups
    local first_word = line:match("%S+")
    if not first_word then
        return
    end
    local hex_obj = require("ever._ui.highlight").commit_hash_to_hex(first_word)
    local hlgroup = hlgroups.EVER_BLAME_HASH .. hex_obj.stripped_hash
    vim.cmd(string.format("highlight %s guifg=%s", hlgroup, hex_obj.hex))
    require("ever._ui.highlight").highlight_line(bufnr, hlgroup, line_num, 1, #first_word)

    local timestamp_pattern = "%d%d%d%d/%d%d/%d%d %d%d:%d%d %a%a"
    local start_index, end_index = line:find(timestamp_pattern)
    require("ever._ui.highlight").highlight_line(bufnr, "Error", line_num, start_index, end_index)
end

---@param bufnr integer
local function set_blame_win_width(bufnr)
    local closing_paren = string.find(vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1], ")")
    vim.print(vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1])
    if closing_paren then
        local number_width = vim.fn.strwidth(tostring(vim.api.nvim_buf_line_count(0))) + 2
        vim.api.nvim_win_set_width(0, closing_paren + number_width)
    end
end

---@param cmd string
M.render = function(cmd)
    local current_filename = vim.api.nvim_buf_get_name(0)
    cmd = cmd .. " " .. current_filename .. " --date=format-local:'%Y/%m/%d %I:%M %p'"
    if not cmd:match("^git ") then
        cmd = "git " .. cmd
    end
    local bufnr = require("ever._ui.elements").new_buffer({ win_config = { split = "left" } })
    set_keymaps(bufnr)
    vim.api.nvim_set_option_value("wrap", false, { win = 0 })
    require("ever._ui.stream").stream_lines(bufnr, cmd, {
        highlight_line = highlight_line,
        on_exit = set_blame_win_width,
        transform_line = function(line)
            local new_line = line:gsub("^(%S*)%s+[^%(]*%(", "%1 (") -- remove the filename when it is shown, e.g. when using -C flag
            return new_line
        end,
        error_code_handlers = {
            [128] = function()
                vim.notify(string.format("%s not tracked by git", current_filename), vim.log.levels.ERROR)
                vim.api.nvim_buf_delete(bufnr, { force = true })
            end,
        },
    })
end

return M
