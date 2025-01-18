local M = {}

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
}
M.status = {
    display_strategy = M.STRATEGIES.FULL,
}

return M
