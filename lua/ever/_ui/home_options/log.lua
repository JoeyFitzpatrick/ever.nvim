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
---@param line string
---@param line_num integer
local function highlight_head_line(bufnr, line, line_num)
    if line:match("^HEAD:") or line:match("^Branch:") then
        local head_start, head_end = line:find("%s%S+")
        require("ever._ui.highlight").highlight_line(bufnr, "Identifier", line_num, head_start, head_end)
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
    if line:match("^%a+:") then
        return { hash = line:match(": (%S+)") }
    end
    return { hash = line:match("%w+") }
end

local DEFAULT_LOG_FORMAT = "--pretty='format:%h %<(25)%cr %<(25)%an %<(25)%s'"

---@param args? string
---@return string
function M._parse_log_cmd(args)
    -- if cmd is nil, the default command is "git log" with special format
    if not args then
        return string.format("git log %s", DEFAULT_LOG_FORMAT)
    end
    local args_without_log_prefix = args:sub(5)
    local cmd_with_format = string.format("git log %s %s", DEFAULT_LOG_FORMAT, args_without_log_prefix)
    if args:match("log%s-$") then
        return cmd_with_format
    end
    -- This checks whether a flag that starts with "-" is present
    -- If not, we're probably just using log on a branch or commit,
    -- so using the special format is fine
    if not args:match("^log.+%s%-") then
        return cmd_with_format
    end
    return "git " .. args -- args already starts with "log "
end

---@param cmd string?
---@return string
local function get_current_head(cmd)
    if cmd then
        local branch = require("ever._core.texter").find_non_dash_arg(cmd:sub(5))
        if branch then
            return "Branch: " .. branch
        end
    end
    local ERROR_MSG = "HEAD: Unable to find current HEAD"
    local current_head, status_code = require("ever._core.run_cmd").run_cmd("git rev-parse --abbrev-ref HEAD")
    if status_code ~= 0 then
        return ERROR_MSG
    end
    -- If current head is HEAD and not a branch, we're in a detached head
    if current_head == "HEAD" then
        local current_head_hash, hash_status_code = require("ever._core.run_cmd").run_cmd("git rev-parse --short HEAD")
        if hash_status_code ~= 0 then
            return ERROR_MSG
        end
        return string.format("HEAD: %s (detached head)", current_head_hash[1])
    end
    return "HEAD: " .. current_head[1]
end

--- This `set_lines` is different than the others, in that it streams content into the buffer
--- instead of writing it all at once.
--- TODO: use standard stream for this
---@param bufnr integer
---@param opts ever.UiRenderOpts
local function set_lines(bufnr, opts)
    local first_line = get_current_head(opts.cmd)
    local start_line = opts.start_line or 0
    vim.bo[bufnr].modifiable = true
    vim.api.nvim_buf_set_lines(bufnr, start_line, start_line + 1, false, { first_line })
    highlight_head_line(bufnr, first_line, start_line)
    start_line = start_line + 1
    local cmd = M._parse_log_cmd(opts.cmd)
    require("ever._ui.stream").stream_lines(
        bufnr,
        cmd,
        { filter_empty_lines = true, highlight_line = highlight_line, start_line = start_line }
    )
    -- This should already be set to false by stream_lines.
    -- Just leaving this in case there's an error there.
    vim.bo[bufnr].modifiable = false
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
    set_lines(bufnr, opts)
    set_keymaps(bufnr, opts)
end

return M
