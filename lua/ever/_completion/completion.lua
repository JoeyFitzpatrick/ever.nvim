local M = {}

---@param cmdline string
---@return string | nil
local function get_subcommand(cmdline)
    local words = {}
    for word in cmdline:gmatch("%S+") do
        table.insert(words, word)
    end
    return words[2]
end

function M._branch_completion()
    local all_branches_command = "git for-each-ref --format='%(refname:short)' refs/heads/ refs/remotes/"
    local branches = vim.fn.systemlist(all_branches_command)
    if vim.v.shell_error ~= 0 then
        return {}
    end
    table.insert(branches, "HEAD")
    return branches
end

--- This function was copied from [mini.git](https://github.com/echasnovski/mini-git).
--- All credit for this goes to Evgeni Chasnovski and the mini.git maintainers.
--- Definitely check out [mini.nvim](https://github.com/echasnovski/mini.nvim), it's pretty sweet!
function M._path_completion(base)
    local cwd = vim.fn.getcwd()
    cwd = cwd:gsub("/+$", "") .. "/"
    local cwd_len = cwd:len()

    -- List elements from (absolute) target directory
    local target_dir = vim.fn.fnamemodify(base, ":h")
    target_dir = (cwd .. target_dir:gsub("^%.$", "")):gsub("/+$", "") .. "/"
    local ok, fs_entries = pcall(vim.fn.readdir, target_dir)
    if not ok then
        return {}
    end

    -- List directories and files separately
    local dirs, files = {}, {}
    for _, entry in ipairs(fs_entries) do
        local entry_abs = target_dir .. entry
        local arr = vim.fn.isdirectory(entry_abs) == 1 and dirs or files
        table.insert(arr, entry_abs)
    end
    dirs = vim.tbl_map(function(x)
        return x .. "/"
    end, dirs)

    -- List ordered directories first followed by ordered files
    local order_ignore_case = function(a, b)
        return a:lower() < b:lower()
    end
    table.sort(dirs, order_ignore_case)
    table.sort(files, order_ignore_case)

    -- Return candidates relative to command's cwd
    local all = dirs
    vim.list_extend(all, files)
    local res = vim.tbl_map(function(x)
        return x:sub(cwd_len + 1)
    end, all)
    return res, "path"
end

--- Takes a git command in command mode, and returns completion options.
---@param arglead string
---@param cmdline string
---@return string[]
M.complete_git_command = function(arglead, cmdline)
    local space_count = 0
    for _ in string.gmatch(cmdline, " ") do
        space_count = space_count + 1
    end
    if space_count == 1 then
        return require("ever._constants.porcelain_commands")
    end
    if space_count > 1 then
        -- Check that we have a valid git subcommand
        local subcommand = get_subcommand(cmdline)
        if not subcommand then
            return {}
        end
        -- Check that we have completion for this subcommand
        local completion_tbl = require("ever._constants.command_options")[subcommand]
        if not completion_tbl then
            return {}
        end

        -- If a "-" is typed, provide option completion, e.g. "--no-verify"
        if arglead:sub(1, 1) == "-" then
            return completion_tbl.options or {}
        end

        if cmdline:match(" %-%- ") then
            return M._path_completion(arglead) or {}
        end

        if completion_tbl.completion_type == "branch" then
            return M._branch_completion()
        end

        if completion_tbl.completion_type == "subcommand" then
            return completion_tbl.subcommands or {}
        end

        if completion_tbl.completion_type == "filepath" then
            return M._path_completion(arglead) or {}
        end

        return completion_tbl.options or {}
    end
    return {}
end

return M
