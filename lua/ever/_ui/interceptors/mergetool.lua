local M = {}

local function get_conflict_lines()
    local run_cmd = require("ever._core.run_cmd").run_cmd

    -- Get the initial list of potential conflict lines
    local potential_conflicts = run_cmd(
        "git -c core.whitespace=-trailing-space,-space-before-tab,-indent-with-non-tab,-tab-in-indent,-cr-at-eol diff --check"
    )

    local filtered_conflicts = {}

    for _, line in ipairs(potential_conflicts) do
        local filename, lnum = line:match("([^:]+):(%d+):")
        if filename and lnum then
            local file = io.open(filename, "r")
            if file then
                for i = 1, tonumber(lnum) do
                    local content = file:read("*line")
                    if i == tonumber(lnum) then
                        if content and content:match("^<<<<<<<") then
                            table.insert(filtered_conflicts, line)
                        end
                        break
                    end
                end
                file:close()
            end
        end
    end

    return filtered_conflicts
end

local function populate_and_open_quickfix()
    -- Clear the current quickfix list
    vim.fn.setqflist({}, "r")

    -- Prepare the entries for the quickfix list
    local qf_entries = {}
    for _, item in ipairs(get_conflict_lines()) do
        local filename, lnum, text = item:match("([^:]+):(%d+): (.+)")
        table.insert(qf_entries, {
            filename = filename,
            lnum = tonumber(lnum),
            text = text,
        })
    end

    -- Set the quickfix list with the new entries
    vim.fn.setqflist(qf_entries, "r")

    -- Open the quickfix window
    vim.cmd("copen")
end

---@param cmd string
function M.render(cmd)
    populate_and_open_quickfix()
end

return M
