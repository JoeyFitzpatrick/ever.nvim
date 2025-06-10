--- All function(s) that can be called externally by other Lua modules.
---
--- If a function's signature here changes in some incompatible way, this
--- package must get a new **major** version.
---
---@module 'trunks'
---

if vim.g.loaded_trunks then
    return
end

require("trunks._core.configuration").initialize_data()
require("trunks._core.highlight").initialize_highlights()
require("trunks._core.signcolumn").initialize_signcolumns()
require("trunks._core.nested-buffers").setup_nested_buffers()
require("trunks._core.autocmds").setup_autocmds()

vim.g.loaded_trunks = true
