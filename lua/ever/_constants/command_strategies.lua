---@alias ever.DisplayStrategy "above" | "below" | "right" | "left" | "full" | "dynamic"
---@alias ever.DisplayStrategyParser fun(cmd: string[]): ever.DisplayStrategy
---@alias ever.ShouldEnterInsert fun(cmd: string[]): boolean

---@class ever.Strategy
---@field display_strategy? ever.DisplayStrategy | ever.DisplayStrategyParser
---@field insert? boolean | ever.ShouldEnterInsert
---@field trigger_redraw? boolean
---@field enter? boolean
---@field win_size? number

local M = {}

---@param cmd string[]
---@return boolean
local function is_interactive_command(cmd)
    local full_screen_options = {
        "-i",
        "--interactive",
    }
    return require("ever._core.tabler").tbls_overlap(cmd, full_screen_options)
end

---@type table<string, ever.DisplayStrategy>
M.STRATEGIES = {
    ABOVE = "above",
    BELOW = "below",
    RIGHT = "right",
    LEFT = "left",
    FULL = "full",
    DYNAMIC = "dynamic",
}

M.default = {
    display_strategy = M.STRATEGIES.BELOW,
    insert = false,
    trigger_redraw = false,
}

---@type ever.Strategy
M.add = {
    display_strategy = function(cmd)
        if is_interactive_command(cmd) then
            return M.STRATEGIES.ABOVE
        end
        return M.STRATEGIES.DYNAMIC
    end,
    insert = is_interactive_command,
    trigger_redraw = true,
}

M.annotate = { insert = true }
M.branch = { display_strategy = M.STRATEGIES.BELOW, trigger_redraw = true }
M.checkout = { trigger_redraw = true }
M["checkout-index"] = { trigger_redraw = true }

---@type ever.Strategy
M.commit = {
    insert = function(cmd)
        local should_not_enter_insert_options = {
            "--allow-empty",
            "--allow-message",
            "--dry-run",
            "--file",
            "--long",
            "--message",
            "--no-edit",
            "--null",
            "--porcelain",
            "--reuse-message",
            "--short",
            "--squash",
            "-C",
            "-F",
            "-m",
            "-z",
        }
        return not require("ever._core.tabler").tbls_overlap(cmd, should_not_enter_insert_options)
    end,
    trigger_redraw = true,
}

M.diff = { display_strategy = M.STRATEGIES.RIGHT, insert = false }
M.fetch = { trigger_redraw = true }
M.merge = { insert = true, trigger_redraw = true }

M.notes = {
    display_strategy = M.STRATEGIES.BELOW,
    insert = function(cmd)
        local should_not_enter_insert_options =
            { "--message", "-m", "copy", "get-ref", "list", "merge", "prune", "remove", "show" }
        return not require("ever._core.tabler").tbls_overlap(cmd, should_not_enter_insert_options)
    end,
}

M.pull = { display_strategy = M.STRATEGIES.DYNAMIC, trigger_redraw = true }
M.push = { display_strategy = M.STRATEGIES.DYNAMIC, trigger_redraw = true }
M.rebase = { insert = true, trigger_redraw = true }
M.reset = { trigger_redraw = true }
M.revert = { trigger_redraw = true }
M.show = { display_strategy = M.STRATEGIES.FULL, insert = true }
M.stage = { trigger_redraw = true }
M.stash = { trigger_redraw = true }
M.switch = { trigger_redraw = true }

return M
