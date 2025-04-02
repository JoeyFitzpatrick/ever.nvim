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

--- This `set_lines` is different than the others, in that it streams content into the buffer
--- instead of writing it all at once.
--- TODO: use standard stream for this
---@param bufnr integer
---@param opts ever.UiRenderOpts
local function set_lines(bufnr, opts)
    local cmd = M._parse_log_cmd(opts.cmd)
    if not cmd:find(DEFAULT_LOG_FORMAT, 1, true) then
        require("ever._ui.stream").stream_lines(bufnr, cmd, { filetype = "git" })
        return
    end
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

    -- Remove existing lines before adding new lines
    -- This is for when we rerender the output
    vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
    vim.api.nvim_buf_set_lines(bufnr, opts.start_line or 0, -1, false, {})
    vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
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
    -- highlight(bufnr, start_line, output)
    -- return output
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
