-- TODO: make this work with current project setup

local _PLUGINS = {
    ["https://github.com/nvim-lualine/lualine.nvim"] = os.getenv("LUALINE_DIR") or "/tmp/lualine.nvim",
    ["https://github.com/nvim-telescope/telescope.nvim"] = os.getenv("TELESCOPE_DIR") or "/tmp/telescope.nvim",
    ["https://github.com/nvim-lua/plenary.nvim"] = os.getenv("PLENARY_DIR") or "/tmp/plenary.nvim",
}

local cloned = false

for url, directory in pairs(_PLUGINS) do
    if vim.fn.isdirectory(directory) ~= 1 then
        print(string.format('Cloning "%s" plug-in to "%s" path.', url, directory))

        vim.fn.system({ "git", "clone", url, directory })

        cloned = true
    end

    vim.opt.rtp:append(directory)
end

if cloned then
    print("Finished cloning.")
end

vim.opt.rtp:append(".")

vim.cmd("runtime plugin/ever.lua")

require("ever")
