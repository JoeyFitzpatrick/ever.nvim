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
    local hash_start, hash_end = line:find("^%w+")
    ui_highlight_line(bufnr, "MatchParen", line_num, hash_start, hash_end)
    local date_start, date_end = line:find(".+ago", hash_end + 1)
    ui_highlight_line(bufnr, "Function", line_num, date_start, date_end)
    local author_start, author_end = line:find("%s%s+(.-)%s%s+", date_end + 1)
    ui_highlight_line(bufnr, "Identifier", line_num, author_start, author_end)
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
    if line:match("^%a+:") then
        return { hash = line:match(": (%S+)") }
    end
    return { hash = line:match("%w+") }
end

local DEFAULT_LOG_FORMAT = "--pretty='format:%h %<(25)%cr %<(25)%an %<(25)%s'"
M.NATIVE_OUTPUT_OPTIONS = {
    "-p",
    "-L",
}

---@param args? string
---@return { cmd: string, use_native_output: boolean, show_head: boolean }
function M._parse_log_cmd(args)
    -- if cmd is nil, or just "log" and whitespace, the default command is "git log" with special format
    if not args or args:match("log%s-$") then
        return { cmd = string.format("git log %s", DEFAULT_LOG_FORMAT), use_native_output = false, show_head = true }
    end

    local native_output = { cmd = "git " .. args, use_native_output = true, show_head = false }
    for _, option in ipairs(M.NATIVE_OUTPUT_OPTIONS) do
        if args:match("%s+" .. option:gsub("%-", "%-")) then
            return native_output
        end
    end

    local args_without_log_prefix = args:sub(5)
    local cmd_with_format = string.format("git log %s %s", DEFAULT_LOG_FORMAT, args_without_log_prefix)

    -- This checks whether a flag that starts with "-" is present
    -- If not, we're probably just using log on a branch or commit,
    -- so showing the branch being logged is desired.
    local show_head = false
    if not args:match("^log.-%s%-") then
        show_head = true
    end
    return { cmd = cmd_with_format, use_native_output = false, show_head = show_head }
end

---@param bufnr integer
---@param opts ever.UiRenderOpts
---@return { use_native_keymaps: boolean }
local function set_lines(bufnr, opts)
    local start_line = opts.start_line or 0
    local cmd_tbl = M._parse_log_cmd(opts.cmd)
    vim.bo[bufnr].modifiable = true

    if cmd_tbl.show_head then
        local first_line = require("ever._ui.utils.get_current_head").get_current_head(opts.cmd)
        vim.api.nvim_buf_set_lines(bufnr, start_line, start_line + 1, false, { first_line })
        require("ever._ui.utils.get_current_head").highlight_head_line(bufnr, first_line, start_line)
        start_line = start_line + 1
    end

    require("ever._ui.stream").stream_lines(bufnr, cmd_tbl.cmd, {
        filter_empty_lines = not cmd_tbl.use_native_output,
        highlight_line = highlight_line,
        start_line = start_line,
        filetype = cmd_tbl.use_native_output and "git" or nil,
    })

    -- This should already be set to false by stream_lines.
    -- Just leaving this in case there's an error there.
    vim.bo[bufnr].modifiable = false
    return { use_native_keymaps = cmd_tbl.use_native_output }
end

---@param bufnr integer
---@param opts ever.UiRenderOpts
local function set_keymaps(bufnr, opts)
    local keymaps = require("ever._ui.keymaps.base").get_keymaps(bufnr, "log", {})
    local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }
    local set = require("ever._ui.keymaps.set").safe_set_keymap

    local keymap_to_command_map = {
        { keymap = keymaps.pull, command = "pull" },
        { keymap = keymaps.push, command = "push" },
    }

    for _, mapping in ipairs(keymap_to_command_map) do
        set("n", mapping.keymap, function()
            vim.cmd("G " .. mapping.command)
        end, keymap_opts)
    end

    set("n", keymaps.checkout, function()
        local line_data = get_line(bufnr)
        if not line_data then
            return
        end
        vim.cmd("G checkout " .. line_data.hash)
    end, keymap_opts)

    set("n", keymaps.commit_details, function()
        local line_data = get_line(bufnr)
        if not line_data then
            return
        end
        require("ever._ui.commit_details").render(line_data.hash, {})
    end, keymap_opts)

    set("n", keymaps.commit_info, function()
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

    set("n", keymaps.rebase, function()
        local line_data = get_line(bufnr)
        if not line_data then
            return
        end
        vim.cmd("G rebase -i " .. line_data.hash .. "^")
    end, keymap_opts)

    set("n", keymaps.reset, function()
        local line_data = get_line(bufnr)
        if not line_data then
            return
        end
        vim.ui.select({ "mixed", "soft", "hard" }, { prompt = "Git reset type: " }, function(selection)
            require("ever._core.run_cmd").run_hidden_cmd("git reset --" .. selection .. " " .. line_data.hash)
            set_lines(bufnr, opts)
        end)
    end, keymap_opts)

    set("n", keymaps.revert, function()
        local line_data = get_line(bufnr)
        if not line_data then
            return
        end
        vim.cmd("G revert " .. line_data.hash .. " --no-commit")
    end, keymap_opts)

    set("n", keymaps.show, function()
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
    vim.api.nvim_set_option_value("wrap", false, { win = 0 })
    local set_lines_result = set_lines(bufnr, opts)
    if set_lines_result.use_native_keymaps then
        require("ever._ui.keymaps.git_filetype_keymaps").set_keymaps(bufnr)
    else
        set_keymaps(bufnr, opts)
    end
end

return M
