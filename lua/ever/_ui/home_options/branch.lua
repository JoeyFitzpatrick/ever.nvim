--- Branch rendering

local M = {}

--- Highlight branch lines
---@param bufnr integer
---@param start_line integer
---@param lines string[]
local function highlight(bufnr, start_line, lines)
    local highlight_groups = require("ever._constants.highlight_groups").highlight_groups
    for line_num, line in ipairs(lines) do
        if line:match("^%*") then
            vim.api.nvim_buf_add_highlight(bufnr, -1, highlight_groups.EVER_DIFF_ADD, line_num + start_line - 1, 2, -1)
            return
        end
    end
end

---@param bufnr integer
---@param opts ever.UiRenderOpts
---@return string[]
local function set_lines(bufnr, opts)
    local start_line = opts.start_line or 0
    local output = require("ever._core.run_cmd").run_cmd("git branch")
    vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
    vim.api.nvim_buf_set_lines(bufnr, start_line, -1, false, output)
    vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
    highlight(bufnr, start_line, output)
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
    return { branch_name = line:sub(3) }
end

---@param bufnr integer
---@param opts ever.UiRenderOpts
local function set_keymaps(bufnr, opts)
    local keymaps = require("ever._ui.keymaps.base").get_ui_keymaps(bufnr, "branch")
    local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }

    ---@param branch_name string
    ---@param delete_type string
    ---@return boolean
    local function delete_branch(branch_name, delete_type)
        local run_cmd = require("ever._core.run_cmd").run_hidden_cmd
        local delete_actions = {
            local_only = function()
                return run_cmd("git branch --delete " .. branch_name) ~= "error"
            end,
            remote_only = function()
                return run_cmd("git push origin --delete " .. branch_name) ~= "error"
            end,
            both = function()
                -- Try local deletion first
                if run_cmd("git branch --delete " .. branch_name) == "error" then
                    return false
                end
                -- Then try remote deletion
                return run_cmd("git push origin --delete " .. branch_name) ~= "error"
            end,
        }
        local action_map = {
            ["local"] = delete_actions.local_only,
            ["remote"] = delete_actions.remote_only,
            ["both"] = delete_actions.both,
        }
        return action_map[delete_type] and action_map[delete_type]() or false
    end

    vim.keymap.set("n", keymaps.delete, function()
        local line_data = get_line(bufnr)
        if not line_data then
            return
        end

        vim.ui.select(
            { "local", "remote", "both" },
            { prompt = "Delete type for branch " .. line_data.branch_name .. ": " },
            function(selection)
                if selection and delete_branch(line_data.branch_name, selection) then
                    set_lines(bufnr, opts)
                end
            end
        )
    end, keymap_opts)

    vim.keymap.set("n", keymaps.log, function()
        local line_data = get_line(bufnr)
        if not line_data then
            return
        end
        vim.cmd("G log " .. line_data.branch_name)
    end, keymap_opts)

    vim.keymap.set("n", keymaps.new_branch, function()
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

    vim.keymap.set("n", keymaps.switch, function()
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

function M.cleanup(bufnr)
    require("ever._core.register").deregister_buffer(bufnr)
end

return M
