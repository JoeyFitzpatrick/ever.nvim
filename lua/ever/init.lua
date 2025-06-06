--- All function(s) that can be called externally by other Lua modules.
---
--- If a function's signature here changes in some incompatible way, this
--- package must get a new **major** version.
---
---@module 'ever'
---

if vim.g.loaded_ever then
    return
end

require("ever._core.configuration").initialize_data()
require("ever._core.highlight").initialize_highlights()
require("ever._core.signcolumn").initialize_signcolumns()
require("ever._core.nested-buffers").setup_nested_buffers()
require("ever._core.autocmds").setup_autocmds()

vim.g.loaded_ever = true
