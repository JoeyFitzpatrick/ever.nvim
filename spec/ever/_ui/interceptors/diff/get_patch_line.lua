local get_patch_line = require("ever._ui.interceptors.diff.hunk")._get_patch_line

local patch = {
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

local function mock_buf_get_lines(first, last)
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
        assert.are.equal(expected, get_patch_line(patch[1], { 0, 0 }))
    end)

    it("generates a valid patch line for a full diff", function()
        mock_buf_get_lines(2, 12)
        local expected = "@@ -53,9 +53,9 @@ local function set_diff_keymaps(bufnr, is_staged)"
        assert.are.equal(expected, get_patch_line(patch[1], { 0, 0 }))
    end)

    it("generates a valid patch line for diff that adds lines", function()
        mock_buf_get_lines(6, nil)
        local expected = "@@ -53,9 +53,10 @@ local function set_diff_keymaps(bufnr, is_staged)"
        assert.are.equal(expected, get_patch_line(patch[1], { 0, 0 }))
    end)

    it("generates a valid patch line for diff that removes lines", function()
        mock_buf_get_lines(5, nil)
        local expected = "@@ -53,9 +53,8 @@ local function set_diff_keymaps(bufnr, is_staged)"
        assert.are.equal(expected, get_patch_line(patch[1], { 0, 0 }))
    end)
end)
