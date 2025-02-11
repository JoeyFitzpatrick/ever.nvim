--- All functions and data to help customize `ever` for this user.
---
---@module 'ever._core.configuration'
---

local vlog = require("ever._vendors.vlog")

local M = {}

-- NOTE: Don't remove this line. It makes the Lua module much easier to reload
vim.g.loaded_ever = false

M.DATA = {}

-- TODO: (you) If you use the vlog.lua for built-in logging, keep the `logging`
-- section. Otherwise delete it.
--
-- It's recommended to keep the `display` section in any case.
--
---@type ever.Configuration
local _DEFAULTS = {
    keymaps = {
        home = {
            next = "l",
            previous = "h",
        },
        branch = {
            delete = "db",
            new_branch = "n",
            switch = "s",
        },
        diff = {
            next_file = "<tab>",
            previous_file = "<S-tab>",
            next_hunk = "i",
            previous_hunk = "p",
            stage_hunk = "sh",
            stage_line = "sl",
        },
        log = {
            commit_info = "i",
            reset = "rs",
            revert = "rv",
            show = "s",
        },
        stash = {
            apply = "a",
            drop = "d",
            pop = "p",
        },
        status = {
            -- TODO: see why using "c" with nowait doesn't work. Could just be my nvim version.
            commit = "co",
            edit_file = "e",
            pull = "p",
            push = "<leader>p",
            restore = "D",
            scroll_diff_down = "J",
            scroll_diff_up = "K",
            stage = "s",
            stage_all = "a",
            stash = "S",
        },
    },
}

function M.initialize_data()
    M.DATA = vim.tbl_deep_extend("force", _DEFAULTS, vim.g.ever_configuration or {})
end

--- Setup `ever` for the first time, if needed.
--- TODO: remove this, as we are handling initialization elsewhere
function M.initialize_data_if_needed()
    if vim.g.loaded_ever then
        return
    end

    M.DATA = vim.tbl_deep_extend("force", _DEFAULTS, vim.g.ever_configuration or {})

    vim.g.loaded_ever = true

    -- vlog.new(M.DATA.logging or {}, true)

    -- vlog.fmt_debug("Initialized ever's configuration.")
end

--- Merge `data` with the user's current configuration.
---
---@param data ever.Configuration? All extra customizations for this plugin.
---@return ever.Configuration # The configuration with 100% filled out values.
---
function M.resolve_data(data)
    M.initialize_data_if_needed()

    return vim.tbl_deep_extend("force", M.DATA, data or {})
end

return M
