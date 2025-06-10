local get_ui = require("trunks._ui.interceptors").get_ui

describe("get ui", function()
    it("should return a function for commands that trigger a UI", function()
        assert.are.equal("function", type(get_ui(""))) -- empty command triggers home UI
        assert.are.equal("function", type(get_ui("difftool"))) -- difftool UI
        assert.are.equal("function", type(get_ui("difftool commit1 commit2"))) -- difftool UI
    end)
end)
