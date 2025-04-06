--- Branch rendering

local M = {}

--- Highlight branch lines
---@param bufnr integer
---@param start_line integer
---@param lines string[]
local function highlight(bufnr, start_line, lines)
    local highlight_groups = require("ever._constants.highlight_groups").highlight_groups
    for i, line in ipairs(lines) do
        local line_num = i + start_line - 1
        if line:match("^%*") then
            vim.api.nvim_buf_add_highlight(bufnr, -1, highlight_groups.EVER_DIFF_ADD, line_num, 2, -1)
        end
    end
    require("ever._ui.utils.num_commits_pull_push").highlight_num_commits(bufnr, start_line, lines)
end

---@param bufnr integer
---@param opts ever.UiRenderOpts
---@return string[]
local function set_lines(bufnr, opts)
    local start_line = opts.start_line or 0
    -- if cmd is nil, the default command is "git branch"
    if not opts.cmd then
        opts.cmd = "branch"
    end
    local output = require("ever._core.run_cmd").run_cmd(string.format("git %s", opts.cmd))
    vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
    vim.api.nvim_buf_set_lines(bufnr, start_line, -1, false, output)
    vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
    highlight(bufnr, start_line, output)
    require("ever._ui.utils.num_commits_pull_push").set_num_commits_to_pull_and_push(
        bufnr,
        { highlight = highlight, start_line = opts.start_line, line_type = "branch" }
    )
    return output
end

---@param bufnr integer
---@param line_num? integer
---@return { branch_name: string } | nil
local function get_line(bufnr, line_num)
    line_num = line_num or vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1]
    if line == "" then
        return nil
    end
    return { branch_name = line:match("%S+", 3) }
end

---@param bufnr integer
---@param opts ever.UiRenderOpts
local function set_keymaps(bufnr, opts)
    local keymaps = require("ever._ui.keymaps.base").get_keymaps(bufnr, "branch", {})
    local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }
    local set = require("ever._ui.keymaps.set").safe_set_keymap

    ---@param branch_name string
    ---@param delete_type "local" | "remote" | "both"
    local function delete_branch(branch_name, delete_type)
        local run_cmd = function(cmd)
            return require("ever._core.run_cmd").run_hidden_cmd(cmd, { error_codes_to_ignore = { 1 } })
        end
        local delete_actions = {
            local_only = function()
                return run_cmd("git branch --delete " .. branch_name)
            end,
            remote_only = function()
                return run_cmd("git push origin --delete " .. branch_name)
            end,
            both = function()
                -- Try local deletion first
                local status, code = run_cmd("git branch --delete " .. branch_name)
                if status == "error" then
                    return status, code
                end
                -- Then try remote deletion
                return run_cmd("git push origin --delete " .. branch_name)
            end,
        }
        local action_map = {
            ["local"] = delete_actions.local_only,
            ["remote"] = delete_actions.remote_only,
            ["both"] = delete_actions.both,
        }
        assert(action_map[delete_type], "Attempt to delete branch with invalid delete type: " .. delete_type)
        local status, code = action_map[delete_type]()
        if code == 1 and status == "error" and delete_type ~= "remote" then
            require("ever._ui.popups.popup").render_popup({
                buffer_name = "EverBranchDeleteConfirm",
                title = "Branch "
                    .. require("ever._core.texter").surround_with_quotes(branch_name)
                    .. " is not fully merged. Delete anyway?",
                mappings = {
                    {
                        keys = "y",
                        description = "Yes",
                        action = function()
                            require("ever._core.run_cmd").run_hidden_cmd("git branch -D " .. branch_name)
                            set_lines(bufnr, opts)
                        end,
                    },
                    {
                        keys = "n",
                        description = "No",
                        -- This is a no-op, and the popup will close
                        action = function() end,
                    },
                },
            })
        end
        set_lines(bufnr, opts)
    end

    set("n", keymaps.delete, function()
        local line_data = get_line(bufnr)
        if not line_data then
            return
        end

        require("ever._ui.popups.popup").render_popup({
            buffer_name = "EverDeleteBranch",
            title = "Delete Branch",
            mappings = {
                {
                    keys = "l",
                    description = "Local",
                    action = function()
                        delete_branch(line_data.branch_name, "local")
                    end,
                },
                {
                    keys = "r",
                    description = "Remote",
                    action = function()
                        delete_branch(line_data.branch_name, "remote")
                    end,
                },
                {
                    keys = "b",
                    description = "Both",
                    action = function()
                        delete_branch(line_data.branch_name, "both")
                    end,
                },
            },
        })
    end, keymap_opts)

    local keymap_to_command_map = {
        { keymap = keymaps.pull, command = "pull" },
        { keymap = keymaps.push, command = "push" },
    }

    for _, mapping in ipairs(keymap_to_command_map) do
        set("n", mapping.keymap, function()
            vim.cmd("G " .. mapping.command)
        end, keymap_opts)
    end

    set("n", keymaps.log, function()
        local line_data = get_line(bufnr)
        if not line_data then
            return
        end
        local log_bufnr = require("ever._ui.elements").new_buffer({ buffer_name = "EverLog-" .. os.tmpname() })
        require("ever._ui.home_options.log").render(
            log_bufnr,
            { start_line = 0, cmd = "log " .. line_data.branch_name }
        )
    end, keymap_opts)

    set("n", keymaps.new_branch, function()
        local line_data = get_line(bufnr)
        if not line_data then
            return
        end
        vim.ui.input({ prompt = "Name for new branch off of " .. line_data.branch_name .. ": " }, function(input)
            if not input then
                return
            end
            local result = require("ever._core.run_cmd").run_hidden_cmd("git switch --create " .. input)
            if result == "error" then
                return
            end
            set_lines(bufnr, opts)
        end)
    end, keymap_opts)

    set("n", keymaps.rename, function()
        local line_data = get_line(bufnr)
        if not line_data then
            return
        end
        vim.ui.input({ prompt = "New name for branch " .. line_data.branch_name .. ": " }, function(input)
            if not input then
                return
            end
            vim.cmd(string.format("G branch -m %s %s", line_data.branch_name, input))
        end)
    end, keymap_opts)

    set("n", keymaps.switch, function()
        local line_data = get_line(bufnr)
        if not line_data then
            return
        end
        local result = require("ever._core.run_cmd").run_hidden_cmd("git switch " .. line_data.branch_name)
        if result == "error" then
            return
        end
        set_lines(bufnr, opts)
    end, keymap_opts)
end

---@param bufnr integer
---@param opts ever.UiRenderOpts
function M.render(bufnr, opts)
    set_lines(bufnr, opts)
    set_keymaps(bufnr, opts)
end

return M
