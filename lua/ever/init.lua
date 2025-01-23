--- All function(s) that can be called externally by other Lua modules.
---
--- If a function's signature here changes in some incompatible way, this
--- package must get a new **major** version.
---
---@module 'ever'
---

local configuration = require("ever._core.configuration")

local M = {}

configuration.initialize_data_if_needed()

return M
