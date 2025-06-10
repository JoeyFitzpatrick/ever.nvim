local should_stage_files = require("trunks._ui.home_options.status.status_utils").should_stage_files

describe("should stage files", function()
    it("should return true if any files are unstaged", function()
        local files_with_unstaged_files = {
            " A  lua/trunks/_ui/home_options/status/status_utils.lua",
            " D lua/trunks/_ui/home_options/test.lua",
            "?? spec/trunks/_ui/status/should_stage_files_spec.lua",
        }
        assert.are.equal(true, should_stage_files(files_with_unstaged_files))
    end)

    it("should return false if all files are staged", function()
        local all_staged_files = {
            "R  lua/trunks/_ui/home_options/status.lua -> lua/trunks/_ui/home_options/status/init.lua",
            "A  lua/trunks/_ui/home_options/status/status_utils.lua",
            "D  lua/trunks/_ui/home_options/test.lua",
            "A  spec/trunks/_ui/status/should_stage_files_spec.lua",
        }
        assert.are.equal(false, should_stage_files(all_staged_files))
    end)

    it("should return true if files are partially staged", function()
        local all_staged_files = {
            "MM lua/trunks/_ui/home_options/status/status_utils.lua",
            "AM lua/trunks/_ui/home_options/test.lua",
            "A  spec/trunks/_ui/status/should_stage_files_spec.lua",
        }
        assert.are.equal(true, should_stage_files(all_staged_files))
    end)

    it("should return false if no files are given", function()
        assert.are.equal(false, should_stage_files({}))
    end)
end)
