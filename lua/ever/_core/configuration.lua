--- All functions and data to help customize `ever` for this user.
---
---@module 'ever._core.configuration'
---

-- local vlog = require("ever._vendors.vlog")

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
    home = {
        keymaps = {
            next = "l",
            previous = "h",
        },
    },
    auto_display = {
        keymaps = {
            scroll_diff_down = "J",
            scroll_diff_up = "K",
        },
    },
    blame = {
        default_cmd_args = { " --date=format-local:'%Y/%m/%d %I:%M %p'" },
        keymaps = {
            checkout = "c",
            commit_details = "<enter>",
            commit_info = "i",
            diff_file = "d",
            reblame = "r",
            return_to_original_file = "gq",
            show = "s",
        },
    },
    branch = {
        keymaps = {
            delete = "db",
            log = "<enter>",
            new_branch = "n",
            rename = "rn",
            switch = "s",
        },
    },
    commit_details = {
        keymaps = {
            show_all_changes = "<enter>",
        },
    },
    diff = {
        keymaps = {
            next_file = "<tab>",
            previous_file = "<S-tab>",
            next_hunk = "J",
            previous_hunk = "K",
            stage_hunk = "sh",
            stage_line = "sl",
        },
    },
    log = {
        keymaps = {
            checkout = "c",
            commit_details = "<enter>",
            commit_info = "i",
            rebase = "rb",
            reset = "rs",
            revert = "rv",
            show = "s",
        },
    },
    open_files = {
        keymaps = {
            open_in_current_window = "ow",
            open_in_horizontal_split = "oh",
            open_in_new_tab = "ot",
            open_in_vertical_split = "ov",
        },
    },
    reflog = {
        keymaps = {
            checkout = "c",
            commit_details = "<enter>",
            commit_info = "i",
            show = "s",
        },
    },
    stash = {
        keymaps = {
            apply = "a",
            drop = "d",
            pop = "p",
        },
    },
    status = {
        keymaps = {
            commit = "co",
            commit_amend = "ca",
            commit_amend_reuse_message = "cA",
            diff_file = "d",
            edit_file = "<enter>",
            enter_staging_area = "<leader>s",
            pull = "p",
            push = "<leader>p",
            restore = "D",
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
