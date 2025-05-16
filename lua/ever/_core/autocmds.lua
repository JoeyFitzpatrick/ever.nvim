local M = {}

function M.setup_autocmds()
    vim.api.nvim_create_autocmd("WinClosed", {
        desc = "Remove this window from Ever's internal navigation data",
        group = vim.api.nvim_create_augroup("EverRemoveWinFromNavigation", {}),
        callback = function(event)
            local win = tonumber(event.match)
            if not win then
                return
            end
            require("ever._core.register").last_non_ever_buffer_for_win[win] = nil
        end,
    })
end

return M
