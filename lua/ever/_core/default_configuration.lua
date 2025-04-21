---@type ever.Configuration
return {
    home = {
        keymaps = {
            -- NOTE: setting a keymap to nil disables it, e.g. `next = nil`
            next = "l",
            previous = "h",
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
            reblame = "r",
            return_to_original_file = "gq",
            show = "s",
        },
    },
    branch = {
        keymaps = {
            delete = "d",
            log = "<enter>",
            new_branch = "n",
            pull = "p",
            push = "<leader>p",
            rename = "rn",
            switch = "s",
        },
    },
    commit_details = {
        auto_display_on = true,
        keymaps = {
            show_all_changes = "<enter>",
        },
    },
    commit_popup = {
        keymaps = {
            commit = "o",
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
            stage = "s",
        },
    },
    difftool = {
        auto_display_on = true,
    },
    git_filetype = {
        keymaps = {
            show_details = "<enter>",
        },
    },
    log = {
        keymaps = {
            checkout = "c",
            commit_details = "<enter>",
            commit_info = "i",
            pull = "p",
            push = "<leader>p",
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
            edit_file = "<enter>",
            enter_staging_area = "<leader>s",
            pull = "p",
            push = "<leader>p",
            restore = "d",
            stage = "s",
            stage_all = "a",
            stash_popup = "S",
        },
    },
}
