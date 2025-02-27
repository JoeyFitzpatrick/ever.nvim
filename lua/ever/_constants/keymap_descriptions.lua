return {
    ---@type ever.HomeKeymaps
    home = {
        next = "Move to next item",
        previous = "Move to previous item",
    },
    ---@type ever.BlameKeymaps
    blame = {
        checkout = "Checkout commit (with detached HEAD)",
        commit_details = "Show commit details",
        commit_info = "Show commit info",
        diff_file = "Display file diff",
        reblame = "Reblame file at commit",
        return_to_original_file = "Close blame and return to original file",
        show = "Show commit details",
    },
    ---@type ever.BranchKeymaps
    branch = {
        delete = "Delete branch",
        log = "Show branch log",
        new_branch = "Create new branch",
        switch = "Switch branch",
    },
    ---@type ever.CommitDetailsKeymaps
    commit_details = {
        open_in_current_window = "Open file at this commit in current window",
        open_in_horizontal_split = "Open file at this commit in a horizontal split",
        open_in_new_tab = "Open file at this commit in a new tab",
        open_in_vertical_split = "Open file at this commit in a vertical split",
        scroll_diff_down = "Scroll diff down",
        scroll_diff_up = "Scroll diff up",
        show_all_changes = "Show all changes from this commit in a single buffer",
    },
    ---@type ever.DiffKeymaps
    diff = {
        next_file = "Go to next file",
        previous_file = "Go to previous file",
        next_hunk = "Move to next hunk",
        previous_hunk = "Move to previous hunk",
        stage_hunk = "Stage hunk",
        stage_line = "Stage line",
    },
    ---@type ever.LogKeymaps
    log = {
        checkout = "Checkout commit (with detached HEAD)",
        commit_details = "Show commit details",
        commit_info = "Show commit info",
        rebase = "Rebase",
        reset = "Reset",
        revert = "Revert commit",
        show = "Show commit details",
    },
    ---@type ever.StashKeymaps
    stash = {
        apply = "Apply stash",
        drop = "Drop stash",
        pop = "Pop stash",
    },
    ---@type ever.StatusKeymaps
    status = {
        commit = "Commit changes",
        commit_amend = "Amend commit",
        commit_amend_reuse_message = "Amend commit reusing message",
        edit_file = "Edit file",
        enter_staging_area = "Enter staging area (stage hunks/lines)",
        pull = "Pull changes",
        push = "Push changes",
        restore = "Restore file",
        scroll_diff_down = "Scroll diff down",
        scroll_diff_up = "Scroll diff up",
        stage = "Stage file",
        stage_all = "Stage all files",
        stash = "Stash changes",
    },
}
