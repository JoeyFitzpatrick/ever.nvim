--- A collection of types to be included / used in other Lua files.
---
--- These types are either required by the Lua API or required for the normal
--- operation of this Lua plugin.
---
---@module 'ever.types'
---

---@alias vim.log.levels.DEBUG number Messages to show to plugin maintainers.
---@alias vim.log.levels.ERROR number Unrecovered issues to show to the plugin users.
---@alias vim.log.levels.INFO number Informative messages to show to the plugin users.
---@alias vim.log.levels.TRACE number Low-level or spammy messages.
---@alias vim.log.levels.WARN number An error that was recovered but could be an issue.

---@class ever.Configuration
---@field blame ever.BlameConfiguration
---@field home ever.HomeConfiguration
---@field branch ever.BranchConfiguration
---@field commit_details ever.CommitDetailsConfiguration
---@field diff ever.DiffConfiguration
---@field log ever.LogConfiguration
---@field reflog ever.ReflogConfiguration
---@field stash ever.StashConfiguration
---@field status ever.StatusConfiguration

---@class ever.BlameConfiguration
---@field default_cmd_args string[]
---@field keymaps ever.BlameKeymaps

---@class ever.HomeConfiguration
---@field keymaps ever.HomeKeymaps

---@class ever.BranchConfiguration
---@field keymaps ever.BranchKeymaps

---@class ever.CommitDetailsConfiguration
---@field keymaps ever.CommitDetailsKeymaps

---@class ever.DiffConfiguration
---@field keymaps ever.DiffKeymaps

---@class ever.LogConfiguration
---@field keymaps ever.LogKeymaps

---@class ever.ReflogConfiguration
---@field keymaps ever.ReflogKeymaps

---@class ever.StashConfiguration
---@field keymaps ever.StashKeymaps

---@class ever.StatusConfiguration
---@field keymaps ever.StatusKeymaps

---@class ever.HomeKeymaps
---@field next string
---@field previous string

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
---@field rename string
---@field switch string

---@class ever.CommitDetailsKeymaps
---@field open_in_current_window string
---@field open_in_horizontal_split string
---@field open_in_new_tab string
---@field open_in_vertical_split string
---@field scroll_diff_down string
---@field scroll_diff_up string
---@field show_all_changes string

---@class ever.DiffKeymaps
---@field next_file string
---@field previous_file string
---@field next_hunk string
---@field previous_hunk string
---@field stage_hunk string
---@field stage_line string

---@class ever.DifftoolKeymaps
---@field scroll_diff_down string
---@field scroll_diff_up string

---@class ever.LogKeymaps
---@field checkout string
---@field commit_details string
---@field commit_info string
---@field rebase string
---@field reset string
---@field revert string
---@field show string

---@class ever.ReflogKeymaps
---@field checkout string
---@field commit_details string
---@field commit_info string
---@field show string

---@class ever.StashKeymaps
---@field apply string
---@field drop string
---@field pop string
---@field scroll_diff_down string
---@field scroll_diff_up string

---@class ever.StatusKeymaps
---@field commit string
---@field commit_amend string
---@field commit_amend_reuse_message string
---@field edit_file string
---@field enter_staging_area string
---@field pull string
---@field push string
---@field restore string
---@field scroll_diff_down string
---@field scroll_diff_up string
---@field stage string
---@field stage_all string
---@field stash string

---@class ever.ConfigurationCmdparseAutoComplete
---    The settings that control what happens during auto-completion.
---@field display {help_flag: boolean}
---    help_flag = Show / Hide the --help flag during auto-completion.

---@class ever.LoggingConfiguration
---    Control whether or not logging is printed to the console or to disk.
---@field level (
---    | "trace"
---    | "debug"
---    | "info"
---    | "warn" | "error"
---    | "fatal"
---    | vim.log.levels.DEBUG
---    | vim.log.levels.ERROR
---    | vim.log.levels.INFO
---    | vim.log.levels.TRACE
---    | vim.log.levels.WARN)?
---    Any messages above this level will be logged.
---@field use_console boolean?
---    Should print the output to neovim while running. Warning: This is very
---    spammy. You probably don't want to enable this unless you have to.
---@field use_file boolean?
---    Should write to a file.
---@field output_path string?
---    The default path on-disk where log files will be written to.
---    TODO: make this the correct log path
---    Defaults to "/home/selecaoone/.local/share/nvim/plugin_name.log".
