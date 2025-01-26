--- All function(s) that can be called externally by other Lua modules.
---
--- If a function's signature here changes in some incompatible way, this
--- package must get a new **major** version.
---
---@module 'ever'
---

local configuration = require("ever._core.configuration")
local highlight = require("lua.ever._core.highlight")

if vim.g.loaded_ever then
    return
end

configuration.initialize_data()
highlight.initialize_highlights()

vim.g.loaded_ever = true
