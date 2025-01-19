---@alias DisplayStrategy "above" | "below" | "right" | "left" | "full" | "dynamic"
---@alias DisplayStrategyParser fun(cmd: string): DisplayStrategy
---@alias ShouldEnterInsert fun(cmd: string): boolean

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
        local should_not_enter_insert_pattern =
            "%f[%w](-C|--reuse%-message|--squash|--long|--short|--porcelain|-z|--null|-F|--file|-m|--message|--allow%-empty|--allow%-message|--no%-edit|--dry%-run)%f[%W]"
        return not cmd:match(should_not_enter_insert_pattern)
    end,
}

M.status = {
    display_strategy = M.STRATEGIES.FULL,
}

return M
