---@type trunks.Configuration
return {
    -- By default, Trunks attempts to prevent nested nvim sessions, in cases
    -- where a terminal opened by Trunks opens an editor (like the commit editor).
    -- Set this to false to allow "nvim inception" to occur (or handle yourself).
    prevent_nvim_inception = true,
    home = {
        keymaps = {
            -- NOTE: setting a keymap to nil disables it, e.g. `next = nil`
            next = "l", -- Move right through home options
            previous = "h", -- Move left through home options
        },
    },
    auto_display = {
        keymaps = {
            scroll_diff_down = "J",
            scroll_diff_up = "K",
            toggle_auto_display = "<tab>",
        },
    },
    blame = {
        default_cmd_args = { " --date=format-local:'%Y/%m/%d %I:%M %p'" },
        keymaps = {
            checkout = "c",
            commit_details = "<enter>",
            commit_info = "i",
            diff_file = "d",
            reblame = "r", -- Display the file as of the given commit, then blame from that commit
            return_to_original_file = "gq", -- If in reblamed file, return to original
            show = "s", -- Output of `git show` for the given commit
        },
    },
    branch = {
        keymaps = {
            delete = "d", -- Display a popup with branch deletion options
            log = "<enter>", -- Display commits for branch under cursor
            new_branch = "n", -- New branch from branch under cusor
            pull = "p",
            push = "<leader>p",
            rename = "rn", -- Rename branch under cursor
            switch = "s", -- Switch to branch under cursor
        },
    },
    commit_details = {
        auto_display_on = true,
        keymaps = {
            show_all_changes = "<enter>",
        },
    },
    commit_popup = {
        keymaps = { -- Run git commit with various options
            commit = "o", -- Just a regular commit (no options)
            commit_amend = "a",
            commit_amend_reuse_message = "A",
            commit_dry_run = "d",
            commit_no_verify = "n",
        },
    },
    diff = {
        keymaps = {
            next_hunk = "J",
            previous_hunk = "K",
            stage = "s", -- Stage hunk in normal mode, stage selected lines in visual mode
        },
    },
    difftool = {
        auto_display_on = true,
    },
    git_filetype = {
        keymaps = {
            show_details = "<enter>", -- Show details for item under cursor
        },
    },
    log = {
        keymaps = {
            checkout = "c", -- Checkout commmit under cursor
            commit_details = "<enter>",
            commit_info = "i",
            diff_commit_against_head = "d",
            pull = "p",
            push = "<leader>p",
            rebase = "rb", -- Interactive rebase from current commit to commit under cursor
            reset = "rs", -- Reset to commit under cursor
            revert = "rv", -- Revert commit under cursor, but don't commit changes
            revert_and_commit = "rV", -- Revert commit under cursor, and commit the revert
            show = "s",
        },
    },
    open_files = {
        keymaps = { -- When available, these open file under cursor in various UIs
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
            recover = "r",
            show = "s",
        },
    },
    stash = {
        auto_display_on = true,
        keymaps = {
            apply = "a",
            drop = "d",
            pop = "p",
            show = "<enter>",
        },
    },
    stash_popup = {
        keymaps = {
            stash_all = "a",
            stash_staged = "s",
        },
    },
    status = {
        auto_display_on = true,
        keymaps = {
            commit_popup = "c",
            diff_file = "D",
            edit_file = "<enter>", -- Close status UI and navigate to file under cursor
            enter_staging_area = "<leader>s", -- In staging area you can (un)stage hunks or lines
            pull = "p",
            push = "<leader>p",
            restore = "d", -- Display a popup with options for `git restore`
            stage = "s", -- (un)stage file under cursor
            stage_all = "a",
            stash_popup = "S",
        },
    },
}
