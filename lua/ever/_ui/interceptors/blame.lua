local M = {}

---@param bufnr integer
---@param line_num? integer
---@return { hash: string } | nil
local function get_line(bufnr, line_num)
    line_num = line_num or vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1]
    if line == "" then
        return nil
    end
    return { hash = line:match("%w+") }
end

local function set_keymaps(bufnr)
    local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }
    local keymaps = require("ever._ui.keymaps.base").get_ui_keymaps(bufnr, "blame")

    vim.keymap.set("n", "q", function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end, keymap_opts)

    vim.keymap.set("n", keymaps.checkout, function()
        local line_data = get_line(bufnr)
        if not line_data then
            return
        end
        vim.cmd("G checkout " .. line_data.hash)
    end, keymap_opts)

    vim.keymap.set("n", keymaps.commit_details, function()
        local line_data = get_line(bufnr)
        if not line_data then
            return
        end
        require("ever._ui.commit_details").render(line_data.hash)
    end, keymap_opts)

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
    if closing_paren then
        local number_width = vim.fn.strwidth(tostring(vim.api.nvim_buf_line_count(0))) + 2
        vim.api.nvim_win_set_width(0, closing_paren + number_width)
    end
end

---@param cmd string
M.render = function(cmd)
    local current_filename = vim.api.nvim_buf_get_name(0)
    cmd = cmd
        .. " "
        .. current_filename
        .. table.concat(require("ever._core.configuration").DATA.blame.default_cmd_args, " ")
    if not cmd:match("^git ") then
        cmd = "git " .. cmd
    end
    local bufnr = require("ever._ui.elements").new_buffer({
        win_config = { split = "left", width = math.floor(vim.o.columns * 0.33) },
    })
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
