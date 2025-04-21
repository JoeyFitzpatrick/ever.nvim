# Yet Another Neovim Git Client

| <!-- -->     | <!-- -->                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
|--------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Build Status | [![unittests](https://img.shields.io/github/actions/workflow/status/JoeyFitzpatrick/ever.nvim/test.yml?branch=main&style=for-the-badge&label=Unittests)](https://github.com/JoeyFitzpatrick/ever.nvim/actions/workflows/test.yml)  [![documentation](https://img.shields.io/github/actions/workflow/status/JoeyFitzpatrick/ever.nvim/documentation.yml?branch=main&style=for-the-badge&label=Documentation)](https://github.com/JoeyFitzpatrick/ever.nvim/actions/workflows/documentation.yml)  [![luacheck](https://img.shields.io/github/actions/workflow/status/JoeyFitzpatrick/ever.nvim/luacheck.yml?branch=main&style=for-the-badge&label=Luacheck)](https://github.com/JoeyFitzpatrick/ever.nvim/actions/workflows/luacheck.yml) [![llscheck](https://img.shields.io/github/actions/workflow/status/JoeyFitzpatrick/ever.nvim/llscheck.yml?branch=main&style=for-the-badge&label=llscheck)](https://github.com/JoeyFitzpatrick/ever.nvim/actions/workflows/llscheck.yml) [![stylua](https://img.shields.io/github/actions/workflow/status/JoeyFitzpatrick/ever.nvim/stylua.yml?branch=main&style=for-the-badge&label=Stylua)](https://github.com/JoeyFitzpatrick/ever.nvim/actions/workflows/stylua.yml)  [![urlchecker](https://img.shields.io/github/actions/workflow/status/JoeyFitzpatrick/ever.nvim/urlchecker.yml?branch=main&style=for-the-badge&label=URLChecker)](https://github.com/JoeyFitzpatrick/ever.nvim/actions/workflows/urlchecker.yml)  |
| License      | [![License-MIT](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](https://github.com/JoeyFitzpatrick/ever.nvim/blob/main/LICENSE)


# What is Ever?

Ever is a Neovim git client. It takes some ideas from [vim-fugitive](https://github.com/tpope/vim-fugitive), [lazygit](https://github.com/jesseduffield/lazygit), [magit](https://magit.vc/), and [git](https://git-scm.com/) itself, and introduces some other ideas. The main features are:
- Most valid git command can be called via command-mode, e.g. `:G commit`, like fugitive
- Autocompletion for those commands, e.g. typing `:G switch` will cause valid branches to be autocompleted
- Keymaps for common actions in various git contexts, e.g. `n` to create a new branch from the branch UI, like lazygit
- Rich UIs that always show the up-to-date git status and provide context for available actions
- Easy and straightforward customizability

🚧 NOTE: this plugin is in an alpha state. API changes and bugs are expected. 🚧


# Installation
- [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
    "JoeyFitzpatrick/ever.nvim",
    -- TODO: (you) - Make sure your first release matches v1.0.0 so it auto-releases!
    version = "v1.*",
}
```

Note: lazy loading is handled internally, so it is not required to lazy load Ever. With that being said, if you really want to lazy load Ever, you should be able to lazy load it however you normally lazy load plugins.


# Configuration
(These are default values)

- [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
    "JoeyFitzpatrick/ever.nvim",
    config = function()
        vim.g.ever_configuration = {
            -- Default configuration
            -- End of default configuration
        }
    end
}
```

# Usage
1. To use this plugin, simply call git commands from command mode, using the `:G` command. Many commands will simply call the git command in terminal mode, with some improvements:
* The terminal can be remove by pressing "enter", to make it convenient to remove the terminal once you're done with the output

There are some advantages to using terminal mode for these commands, as opposed to a regular buffer or printing command output:
* Command output will sometimes be mangled when translated to a buffer or printed, this is avoided with a terminal
* Command output keeps it's coloring
* Existing tools such as `delta` that improve git output can still be leveraged

Note that using the `%` character will expand it to the current buffer's filename, similar to vim-fugitive, e.g. `:G log --follow %` to see commits that changed the current file.


# Optional Dependencies

[Delta](https://github.com/dandavison/delta) - improved git diff output (used in the demos/examples)

# Development and Contributing
I welcome users of any experience level to contribute to Ever and improve the project. If you'd like to contribute by writing code, please run `scripts/dev_setup/dev_setup.sh` first, which will set up a pre-commit hook that runs tests and some checks. The same checks run in CI, but this will help you catch issues before pushing up code. Note that you may need to run `chmod +x scripts/dev_setup/dev_setup.sh` first, to set up correct permissions to run the script.

There are templates for asking questions, bug reports, and feature requests, all which are also good ways to contribute.

# Tests
## Initialization
Run this line once before calling any `busted` command

```sh
eval $(luarocks path --lua-version 5.1 --bin)
```


## Running
Run all tests
```sh
luarocks test --test-type busted
# Or manually
busted --helper spec/minimal_init.lua .
# Or with Make
make test
```

Run test based on tags
```sh
busted --helper spec/minimal_init.lua . --tags=simple
```

# Tracking Updates
See [doc/news.txt](doc/news.txt) for updates.
