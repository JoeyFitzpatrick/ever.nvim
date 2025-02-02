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
---@field keymaps ever.Keymaps -- All of the keymaps in Ever

---@class ever.Keymaps
---@field home ever.KeymapsHome
---@field branch ever.KeymapsBranch
---@field log ever.KeymapsLog
---@field stash ever.KeymapsStash
---@field status ever.KeymapsStatus

---@class ever.KeymapsHome
---@field next string
---@field previous string

---@class ever.KeymapsBranch
---@field delete string
---@field new_branch string
---@field switch string

---@class ever.KeymapsLog
---@field commit_info string
---@field reset string
---@field revert string
---@field show string

---@class ever.KeymapsStash
---@field apply string
---@field drop string
---@field pop string

---@class ever.KeymapsStatus
---@field commit string
---@field edit_file string
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
