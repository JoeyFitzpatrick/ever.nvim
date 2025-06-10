local filter_patch_lines = require("trunks._ui.interceptors.diff.hunk")._filter_patch_lines

local original_patch = {
    "         end",
    "         local cmd",
    "         if is_staged then",
    '-            cmd = "git apply --reverse --cached --whitespace=nowarn -"',
    '+            cmd = "git apply --reverse --cached --whitespace=fix -"',
    "         else",
    '-            cmd = "git apply --cached --whitespace=nowarn -"',
    '+            cmd = "git apply --cached --whitespace=fix -"',
    "         end",
    '         require("trunks._core.run_cmd").run_cmd(cmd, { stdin = hunk.patch_lines, rerender = true })',
    "     end, keymap_opts)",
}

describe("filter patch lines", function()
    it("should generate a valid partial patch for an unstaged file", function()
        local expected = {
            "         end",
            "         local cmd",
            "         if is_staged then",
            '-            cmd = "git apply --reverse --cached --whitespace=nowarn -"',
            '+            cmd = "git apply --reverse --cached --whitespace=fix -"',
            "         else",
            -- notice that the "-" line was changed to a " " line,
            -- and the "+" line was removed
            '             cmd = "git apply --cached --whitespace=nowarn -"',
            "         end",
            '         require("trunks._core.run_cmd").run_cmd(cmd, { stdin = hunk.patch_lines, rerender = true })',
            "     end, keymap_opts)",
        }
        assert.are.same(expected, filter_patch_lines(original_patch, { 4, 5 }, false))
    end)

    it("should generate a valid full patch for an unstaged file", function()
        local expected = original_patch
        assert.are.same(expected, filter_patch_lines(original_patch, { 1, 11 }, false))
    end)

    it("should generate a valid partial patch for an staged file", function()
        local expected = {
            "         end",
            "         local cmd",
            "         if is_staged then",
            '-            cmd = "git apply --reverse --cached --whitespace=nowarn -"',
            '+            cmd = "git apply --reverse --cached --whitespace=fix -"',
            "         else",
            -- notice that the "+" line was changed to a " " line,
            -- and the "-" line was removed
            '             cmd = "git apply --cached --whitespace=fix -"',
            "         end",
            '         require("trunks._core.run_cmd").run_cmd(cmd, { stdin = hunk.patch_lines, rerender = true })',
            "     end, keymap_opts)",
        }
        assert.are.same(expected, filter_patch_lines(original_patch, { 4, 5 }, true))
    end)

    it("should generate a valid full patch for an staged file", function()
        local expected = original_patch
        assert.are.same(expected, filter_patch_lines(original_patch, { 1, 11 }, true))
    end)
end)
