--- Basic API tests.
---
--- This module is pretty specific to this ever so you'll most
--- likely want to delete or heavily modify this file. But it does give a quick
--- look how to mock a test and some things you can do with Neovim/busted.
---
---@module 'ever.ever_spec'
---

local configuration = require("ever._core.configuration")
local ever = require("plugin.ever")
local vlog = require("ever._vendors.vlog")

---@class ever.Configuration
local _CONFIGURATION_DATA

---@type string[]
local _DATA = {}

local _ORIGINAL_NOTIFY = vim.notify

--- Keep track of text that would have been printed. Save it to a variable instead.
---
---@param data string Some text to print to stdout.
---
local function _save_prints(data)
    table.insert(_DATA, data)
end

--- Mock all functions / states before a unittest runs (call this before each test).
local function _initialize_prints()
    vim.notify = _save_prints
end

--- Write a log file so we can query its later later.
local function _make_fake_log(path)
    local file = io.open(path, "w") -- Open the file in write mode

    if not file then
        error(string.format('Path "%s" is not writable.', path))
    end

    file:write("aaa\nbbb\nccc\n")
    file:close()
end

--- Reset all functions / states to their previous settings before the test had run.
local function _reset_prints()
    vim.notify = _ORIGINAL_NOTIFY
    _DATA = {}
end

--- Wait for our (mocked) unittest variable to get some data back.
---
---@param timeout number?
---    The milliseconds to wait before continuing. If the timeout is exceeded
---    then we stop waiting for all of the functions to call.
---
local function _wait_for_result(timeout)
    if timeout == nil then
        timeout = 1000
    end

    vim.wait(timeout, function()
        return not vim.tbl_isempty(_DATA)
    end)
end

-- describe("hello world API - say phrase/word", function()
--     before_each(_initialize_prints)
--     after_each(_reset_prints)
--
--     it("runs #hello-world with default `say phrase` arguments - 001", function()
--         ever.run_hello_world_say_phrase({ "" })
--
--         assert.same({ "No phrase was given" }, _DATA)
--     end)
--
--     it("runs #hello-world with default `say phrase` arguments - 002", function()
--         ever.run_hello_world_say_phrase({})
--
--         assert.same({ "No phrase was given" }, _DATA)
--     end)
--
--     it("runs #hello-world with default `say word` arguments - 001", function()
--         ever.run_hello_world_say_word("")
--
--         assert.same({ "No word was given" }, _DATA)
--     end)
--
--     it("runs #hello-world say phrase - with all of its arguments", function()
--         ever.run_hello_world_say_phrase({ "Hello,", "World!" }, 2, "lowercase")
--
--         assert.same({ "Saying phrase", "hello, world!", "hello, world!" }, _DATA)
--     end)
--
--     it("runs #hello-world say word - with all of its arguments", function()
--         ever.run_hello_world_say_phrase({ "Hi" }, 2, "uppercase")
--
--         assert.same({ "Saying phrase", "HI", "HI" }, _DATA)
--     end)
-- end)
