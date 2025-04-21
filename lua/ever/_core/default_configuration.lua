---@type ever.Configuration
return {
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
            pull = "p", -- Run git pull
            push = "<leader>p", -- Run git push
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
