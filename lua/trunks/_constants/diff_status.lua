---@alias trunks.DiffStatus  "A" | "C" | "D" | "M" | "R" | "T" | "U" | "X" | "B"

local M = {}

---@type table<string, trunks.DiffStatus>
M.DIFF_STATUSES = {
    ADDED = "A",
    COPIED = "C",
    DELETED = "D",
    MODIFIED = "M",
    RENAMED = "R",
    TYPE_CHANGED = "T",
    UNMERGED = "U",
    UNKNOWN = "X",
    PAIRING_BROKEN = "B",
}

return M
