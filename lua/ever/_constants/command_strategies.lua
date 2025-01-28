---@alias DisplayStrategy "above" | "below" | "right" | "left" | "full" | "dynamic"
---@alias DisplayStrategyParser fun(cmd: string[]): DisplayStrategy
---@alias ShouldEnterInsert fun(cmd: string[]): boolean

---@class Strategy
---@field display_strategy? DisplayStrategy | DisplayStrategyParser
---@field insert? boolean | ShouldEnterInsert

local M = {}

---@type table<string, DisplayStrategy>
M.STRATEGIES = {
    ABOVE = "above",
    BELOW = "below",
    RIGHT = "right",
    LEFT = "left",
    FULL = "full",
    DYNAMIC = "dynamic",
}

M.default = {
    display_strategy = M.STRATEGIES.DYNAMIC,
    insert = false,
}

M.branch = {
    display_strategy = M.STRATEGIES.BELOW,
}

---@type Strategy
M.commit = {
    display_strategy = M.STRATEGIES.BELOW,
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
}

M.diff = {
    display_strategy = M.STRATEGIES.RIGHT,
    insert = false,
}

M.notes = {
    display_strategy = M.STRATEGIES.BELOW,
    insert = function(cmd)
        local should_not_enter_insert_options =
            { "--message", "-m", "copy", "get-ref", "list", "merge", "prune", "remove", "show" }
        return not require("ever._core.tabler").tbls_overlap(cmd, should_not_enter_insert_options)
    end,
}

M.status = {
    display_strategy = M.STRATEGIES.FULL,
}

return M
