local PULL_DESCRIPTION = "Pull changes"
local PUSH_DESCRIPTION = "Push changes"

return {
    ---@type ever.HomeKeymaps
    home = {
        next = "Move to next item",
        previous = "Move to previous item",
    },
    ---@type ever.AutoDisplayKeymaps
    auto_display = {
        scroll_diff_down = "Scroll auto-display window down",
        scroll_diff_up = "Scroll auto-display window up",
        toggle_auto_display = "Toggle auto-display window",
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
        pull = PULL_DESCRIPTION,
        push = PUSH_DESCRIPTION,
        rename = "Rename branch",
        switch = "Switch branch",
    },
    ---@type ever.CommitDetailsKeymaps
    commit_details = {
        show_all_changes = "Show all changes from this commit in a single buffer",
    },
    ---@type ever.CommitPopupKeymaps
    commit_popup = {
        commit = "Regular commit",
        commit_amend = "Amend commit",
        commit_amend_reuse_message = "Amend commit reusing message",
        commit_dry_run = "Run dry run commit",
        commit_no_verify = "Commit with --no-verify to skip pre-commit hooks",
    },
    ---@type ever.DiffKeymaps
    diff = {
        next_hunk = "Move to next hunk",
        previous_hunk = "Move to previous hunk",
        stage = "Stage hunk under cursor or visually selected lines",
    },
    ---@type ever.GitFiletypeKeymaps
    git_filetype = {
        show_details = "Show details for item under cursor",
    },
    ---@type ever.LogKeymaps
    log = {
        checkout = "Checkout commit (with detached HEAD)",
        commit_details = "Show commit details",
        commit_info = "Show commit info",
        pull = PULL_DESCRIPTION,
        push = PUSH_DESCRIPTION,
        rebase = "Rebase",
        reset = "Reset",
        revert = "Revert commit",
        show = "Show commit details",
    },
    ---@type ever.OpenFilesKeymaps
    open_files = {
        open_in_current_window = "Open file at this commit in current window",
        open_in_horizontal_split = "Open file at this commit in a horizontal split",
        open_in_new_tab = "Open file at this commit in a new tab",
        open_in_vertical_split = "Open file at this commit in a vertical split",
    },
    ---@type ever.ReflogKeymaps
    reflog = {
        checkout = "Checkout commit (with detached HEAD)",
        commit_details = "Show commit details",
        commit_info = "Show commit info",
        show = "Show commit details",
    },
    ---@type ever.StashKeymaps
    stash = {
        apply = "Apply stash",
        drop = "Drop stash",
        pop = "Pop stash",
        show = "Show stash",
    },
    ---@type ever.StashPopupKeymaps
    stash_popup = {
        stash_all = "Stash all changes",
        stash_staged = "Stash staged changes",
    },
    ---@type ever.StatusKeymaps
    status = {
        commit_popup = "Open commit command popup",
        diff_file = "Diff file",
        edit_file = "Edit file",
        enter_staging_area = "Enter staging area (stage hunks/lines)",
        pull = PULL_DESCRIPTION,
        push = PUSH_DESCRIPTION,
        restore = "Restore file",
        stage = "Stage file",
        stage_all = "Stage all files",
        stash_popup = "Open stash command popup",
    },
}
