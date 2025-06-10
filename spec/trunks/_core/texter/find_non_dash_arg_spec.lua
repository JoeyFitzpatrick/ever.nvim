local find_non_dash_arg = require("trunks._core.texter").find_non_dash_arg

describe("find_non_dash_arg", function()
    it("should return a value when there is an arg without dashes in the input", function()
        assert.are.equal("some-branch", find_non_dash_arg("some-branch"))
    end)

    it("should return a value when there args with and without dashes in the input", function()
        assert.are.equal("some-branch", find_non_dash_arg("--oneline --some-flag -p some-branch"))
    end)

    it("should return nil when there is no arg without dashes in the input", function()
        assert.are.equal(nil, find_non_dash_arg("--oneline"))
    end)

    it("should return nil when the only args are single-dash options", function()
        assert.are.equal(nil, find_non_dash_arg("-W -C -C -C"))
    end)

    it("should consider an arg with two dashes and a space as having two dashes and return nil", function()
        assert.are.equal(nil, find_non_dash_arg("-- some-filepath/file.txt"))
    end)
end)
