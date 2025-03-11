local M = {}

local KEYMAPS_ARE_SET = false

local function get_all_conflict_lines()
    local run_cmd = require("ever._core.run_cmd").run_cmd

    -- Get the initial list of potential conflict lines
    local potential_conflicts = run_cmd(
        -- luacheck: ignore 631
        "git -c core.whitespace=-trailing-space,-space-before-tab,-indent-with-non-tab,-tab-in-indent,-cr-at-eol diff --check"
    )

    local filtered_conflicts = {}

    for _, line in ipairs(potential_conflicts) do
        local filename, lnum = line:match("([^:]+):(%d+):")
        if filename and lnum then
            local file = io.open(filename, "r")
            if file then
                for i = 1, tonumber(lnum) do
                    local content = file:read("*line")
                    if i == tonumber(lnum) then
                        if content and content:match("^<<<<<<<") then
                            table.insert(filtered_conflicts, line)
                        end
                        break
                    end
                end
                file:close()
            end
        end
    end

    return filtered_conflicts
end

local function populate_and_open_quickfix()
    -- Clear the current quickfix list
    vim.fn.setqflist({}, "r")

    -- Prepare the entries for the quickfix list
    local qf_entries = {}
    for _, item in ipairs(get_all_conflict_lines()) do
        local filename, lnum, text = item:match("([^:]+):(%d+): (.+)")
        table.insert(qf_entries, {
            filename = filename,
            lnum = tonumber(lnum),
            text = text,
        })
    end

    -- Set the quickfix list with the new entries
    vim.fn.setqflist(qf_entries, "r")

    -- Open the quickfix window
    vim.cmd("copen")
end

local function get_local_conflict_lines()
    local start_line = vim.fn.search("^<<<<<<< HEAD", "bcnW")
    local end_line = vim.fn.search("^>>>>>>> ", "nW")

    if start_line == 0 or end_line == 0 then
        return nil
    end

    return vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
end

---@param strategy "base" | "ours" | "theirs" | "all"
local function replace_conflict(strategy)
    local conflict_lines = get_local_conflict_lines()

    if not conflict_lines then
        print("No merge conflict found at cursor position.")
        return
    end

    local resolved_lines = require("ever._ui.interceptors.mergetool.handle_merge_conflict").resolve_merge_conflict(
        conflict_lines,
        strategy
    )
    local start_line = vim.fn.search("^<<<<<<< HEAD", "bcnW")
    local end_line = vim.fn.search("^>>>>>>> ", "nW")

    vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, resolved_lines)
end

local function set_keymaps()
    local set = require("ever._ui.keymaps.set").safe_set_keymap

    set("n", "<Plug>(Ever-resolve-base)", function()
        replace_conflict("base")
    end, { noremap = true, silent = true })

    set("n", "<Plug>(Ever-resolve-ours)", function()
        replace_conflict("ours")
    end, { noremap = true, silent = true })

    set("n", "<Plug>(Ever-resolve-theirs)", function()
        replace_conflict("theirs")
    end, { noremap = true, silent = true })

    set("n", "<Plug>(Ever-resolve-all)", function()
        replace_conflict("all")
    end, { noremap = true, silent = true })
end

function M.render()
    populate_and_open_quickfix()
    if not KEYMAPS_ARE_SET then
        set_keymaps()
        KEYMAPS_ARE_SET = true
    end
end

return M
