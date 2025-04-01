local get_patch_line = require("ever._ui.interceptors.diff.hunk")._get_patch_line

local unstaged_patch = {
    "@@ -53,9 +58,9 @@ local function set_diff_keymaps(bufnr, is_staged)",
    "         end",
    "         local cmd",
    "         if is_staged then",
    '-            cmd = "git apply --reverse --cached --whitespace=nowarn -"',
    '+            cmd = "git apply --reverse --cached --whitespace=fix -"',
    "         else",
    '-            cmd = "git apply --cached --whitespace=nowarn -"',
    '+            cmd = "git apply --cached --whitespace=fix -"',
    "         end",
    '         require("ever._core.run_cmd").run_cmd(cmd, { stdin = hunk.patch_lines, rerender = true })',
    "     end, keymap_opts)",
    "",
}

local staged_patch = {
    "@@ -41,9 +41,8 @@ end",
    " ---@param is_staged boolean",
    " local function set_diff_keymaps(bufnr, is_staged)",
    '     require("ever._ui.interceptors.diff.diff_keymaps").set_keymaps(bufnr)',
    '-    local keymaps = require("ever._ui.keymaps.base").get_keymaps(bufnr, "diff", {})',
    '+    local keymaps = require("ever._ui.keymaps.base").get_keymaps(bufnr, "diff", { skip_go_to_last_buffer = true })',
    "     local keymap_opts = { noremap = true, silent = true, buffer = bufnr, nowait = true }",
    '-    require("ever._ui.interceptors.diff.diff_keymaps").set_keymaps(bufnr)',
    '     local set = require("ever._ui.keymaps.set").safe_set_keymap',
    " ",
    '     set("n", keymaps.stage, function()',
    "",
    "",
}

---@param first integer
---@param last? integer
---@param patch? string[]
local function mock_buf_get_lines(first, last, patch)
    patch = patch or unstaged_patch
    local mock_lines = { patch[first], patch[last] }
    vim.api.nvim_buf_get_lines = function()
        return mock_lines
    end
end

describe("get patch line", function()
    it("generates a valid patch line for a partial diff", function()
        -- These lines are the first change, and not the second change
        mock_buf_get_lines(5, 6)
        local expected = "@@ -53,9 +53,9 @@ local function set_diff_keymaps(bufnr, is_staged)"
        -- We're mocking the call to get buffer lines, so the line numbers don't matter
        assert.are.equal(expected, get_patch_line(unstaged_patch[1], { 0, 0 }, false))
    end)

    it("generates a valid patch line for a full diff", function()
        mock_buf_get_lines(2, 12)
        local expected = "@@ -53,9 +53,9 @@ local function set_diff_keymaps(bufnr, is_staged)"
        assert.are.equal(expected, get_patch_line(unstaged_patch[1], { 0, 0 }, false))
    end)

    it("generates a valid patch line for diff that adds lines", function()
        mock_buf_get_lines(6, nil)
        local expected = "@@ -53,9 +53,10 @@ local function set_diff_keymaps(bufnr, is_staged)"
        assert.are.equal(expected, get_patch_line(unstaged_patch[1], { 0, 0 }, false))
    end)

    it("generates a valid patch line for diff that removes lines", function()
        mock_buf_get_lines(5, nil)
        local expected = "@@ -53,9 +53,8 @@ local function set_diff_keymaps(bufnr, is_staged)"
        assert.are.equal(expected, get_patch_line(unstaged_patch[1], { 0, 0 }, false))
    end)

    it("generates a valid patch line for diff on a staged file", function()
        mock_buf_get_lines(5, 6, staged_patch)
        local expected = "@@ -41,8 +41,8 @@ end"
        assert.are.equal(expected, get_patch_line(staged_patch[1], { 0, 0 }, true))
    end)
end)
