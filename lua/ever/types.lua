--- A collection of types to be included / used in other Lua files.
---
--- These types are either required by the Lua API or required for the normal
--- operation of this Lua plugin.
---
---@module 'ever.types'

---@class ever.Configuration
---@field auto_display ever.AutoDisplayConfiguration
---@field blame ever.BlameConfiguration
---@field home ever.HomeConfiguration
---@field branch ever.BranchConfiguration
---@field commit_details ever.CommitDetailsConfiguration
---@field commit_popup ever.CommitPopupConfiguration
---@field diff ever.DiffConfiguration
---@field difftool ever.DifftoolConfiguration
---@field log ever.LogConfiguration
---@field open_files ever.OpenFilesConfiguration
---@field reflog ever.ReflogConfiguration
---@field stash ever.StashConfiguration
---@field stash_popup ever.StashPopupConfiguration
---@field status ever.StatusConfiguration

---@class ever.BlameConfiguration
---@field default_cmd_args string[]
---@field keymaps ever.BlameKeymaps

---@class ever.HomeConfiguration
---@field keymaps ever.HomeKeymaps

---@class ever.AutoDisplayConfiguration
---@field keymaps ever.AutoDisplayKeymaps

---@class ever.BranchConfiguration
---@field keymaps ever.BranchKeymaps

---@class ever.CommitDetailsConfiguration
---@field keymaps ever.CommitDetailsKeymaps
---@field auto_display_on boolean

---@class ever.CommitPopupConfiguration
---@field keymaps ever.CommitPopupKeymaps

---@class ever.DiffConfiguration
---@field keymaps ever.DiffKeymaps

---@class ever.DifftoolConfiguration
---@field auto_display_on boolean

---@class ever.LogConfiguration
---@field keymaps ever.LogKeymaps

---@class ever.OpenFilesConfiguration
---@field keymaps ever.OpenFilesKeymaps

---@class ever.ReflogConfiguration
---@field keymaps ever.ReflogKeymaps

---@class ever.StashConfiguration
---@field keymaps ever.StashKeymaps
---@field auto_display_on boolean

---@class ever.StashPopupConfiguration
---@field keymaps ever.StashPopupKeymaps

---@class ever.StatusConfiguration
---@field keymaps ever.StatusKeymaps
---@field auto_display_on boolean

---@class ever.HomeKeymaps
---@field next string
---@field previous string

---@class ever.AutoDisplayKeymaps
---@field scroll_diff_down string
---@field scroll_diff_up string
---@field toggle_auto_display string

---@class ever.BlameKeymaps
---@field checkout string
---@field diff_file string
---@field commit_details string
---@field commit_info string
---@field reblame string
---@field return_to_original_file string
---@field show string

---@class ever.BranchKeymaps
---@field delete string
---@field log string
---@field new_branch string
---@field pull string
---@field push string
---@field rename string
---@field switch string

---@class ever.CommitDetailsKeymaps
---@field show_all_changes string

---@class ever.CommitPopupKeymaps
---@field commit string
---@field commit_amend string
---@field commit_amend_reuse_message string
---@field commit_dry_run string

---@class ever.DiffKeymaps
---@field next_file string
---@field previous_file string
---@field next_hunk string
---@field previous_hunk string
---@field stage_hunk string
---@field stage_line string

---@class ever.DifftoolKeymaps

---@class ever.LogKeymaps
---@field checkout string
---@field commit_details string
---@field commit_info string
---@field pull string
---@field push string
---@field rebase string
---@field reset string
---@field revert string
---@field show string

---@class ever.OpenFilesKeymaps
---@field open_in_current_window string
---@field open_in_horizontal_split string
---@field open_in_new_tab string
---@field open_in_vertical_split string

---@class ever.ReflogKeymaps
---@field checkout string
---@field commit_details string
---@field commit_info string
---@field show string

---@class ever.StashKeymaps
---@field apply string
---@field drop string
---@field pop string
---@field show string

---@class ever.StashPopupKeymaps
---@field stash_all string
---@field stash_staged string

---@class ever.StatusKeymaps
---@field commit_popup string
---@field diff_file string
---@field edit_file string
---@field enter_staging_area string
---@field pull string
---@field push string
---@field restore string
---@field stage string
---@field stage_all string
---@field stash_popup string
