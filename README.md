# Yet Another Neovim Git Client

| <!-- -->     | <!-- -->                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
|--------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Build Status | [![tests](https://img.shields.io/github/actions/workflow/status/JoeyFitzpatrick/ever.nvim/test.yml?branch=main&style=for-the-badge&label=Unittests)](https://github.com/JoeyFitzpatrick/ever.nvim/actions/workflows/test.yml)  [![documentation](https://img.shields.io/github/actions/workflow/status/JoeyFitzpatrick/ever.nvim/documentation.yml?branch=main&style=for-the-badge&label=Documentation)](https://github.com/JoeyFitzpatrick/ever.nvim/actions/workflows/documentation.yml)  [![luacheck](https://img.shields.io/github/actions/workflow/status/JoeyFitzpatrick/ever.nvim/luacheck.yml?branch=main&style=for-the-badge&label=Luacheck)](https://github.com/JoeyFitzpatrick/ever.nvim/actions/workflows/luacheck.yml) [![llscheck](https://img.shields.io/github/actions/workflow/status/JoeyFitzpatrick/ever.nvim/llscheck.yml?branch=main&style=for-the-badge&label=llscheck)](https://github.com/JoeyFitzpatrick/ever.nvim/actions/workflows/llscheck.yml) [![stylua](https://img.shields.io/github/actions/workflow/status/JoeyFitzpatrick/ever.nvim/stylua.yml?branch=main&style=for-the-badge&label=Stylua)](https://github.com/JoeyFitzpatrick/ever.nvim/actions/workflows/stylua.yml)  [![urlchecker](https://img.shields.io/github/actions/workflow/status/JoeyFitzpatrick/ever.nvim/urlchecker.yml?branch=main&style=for-the-badge&label=URLChecker)](https://github.com/JoeyFitzpatrick/ever.nvim/actions/workflows/urlchecker.yml)  |
| License      | [![License-MIT](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](https://github.com/JoeyFitzpatrick/ever.nvim/blob/main/LICENSE)


# What is Ever?

Ever is a Neovim git client. It takes some ideas from [vim-fugitive](https://github.com/tpope/vim-fugitive), [lazygit](https://github.com/jesseduffield/lazygit), [magit](https://magit.vc/), and [git](https://git-scm.com/) itself, and introduces some other ideas. The main features are:
- Most valid git command can be called via command-mode, e.g. `:G commit`, like fugitive
- Autocompletion for those commands, e.g. typing `:G switch` will cause valid branches to be autocompleted
- Keymaps for common actions in various git contexts, e.g. `n` to create a new branch from the branch UI, like lazygit
- Rich UIs that always show the up-to-date git status and provide context for available actions
- Easy and straightforward customizability

🚧 NOTE: this plugin is in an alpha state. API changes and bugs are expected. 🚧

A roadmap to beta can be found [here](doc/roadmap_to_beta.md).


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
        -- The next two lines allow the lua LSP to autocomplete config options
        ---@module "ever"
        ---@type ever.Configuration
        vim.g.ever_configuration = {
            -- Default configuration
            -- By default, Ever attempts to prevent nested nvim sessions, in cases
            -- where a terminal opened by Ever opens an editor (like the commit editor).
            -- Set this to false to allow "nvim inception" to occur (or handle yourself).
            prevent_nvim_inception = true,
            home = {
                keymaps = {
                    -- NOTE: setting a keymap to nil disables it, e.g. `next = nil`
                    next = "l", -- Move right through home options
                    previous = "h", -- Move left through home options
                },
            },
            auto_display = {
                keymaps = {
                    scroll_diff_down = "J",
                    scroll_diff_up = "K",
                    toggle_auto_display = "<tab>",
                },
            },
            blame = {
                default_cmd_args = { " --date=format-local:'%Y/%m/%d %I:%M %p'" },
                keymaps = {
                    checkout = "c",
                    commit_details = "<enter>",
                    commit_info = "i",
                    diff_file = "d",
                    reblame = "r", -- Display the file as of the given commit, then blame from that commit
                    return_to_original_file = "gq", -- If in reblamed file, return to original
                    show = "s", -- Output of `git show` for the given commit
                },
            },
            branch = {
                keymaps = {
                    delete = "d", -- Display a popup with branch deletion options
                    log = "<enter>", -- Display commits for branch under cursor
                    new_branch = "n", -- New branch from branch under cusor
                    pull = "p",
                    push = "<leader>p",
                    rename = "rn", -- Rename branch under cursor
                    switch = "s", -- Switch to branch under cursor
                },
            },
            commit_details = {
                auto_display_on = true,
                keymaps = {
                    show_all_changes = "<enter>",
                },
            },
            commit_popup = {
                keymaps = { -- Run git commit with various options
                    commit = "o", -- Just a regular commit (no options)
                    commit_amend = "a",
                    commit_amend_reuse_message = "A",
                    commit_dry_run = "d",
                    commit_no_verify = "n",
                },
            },
            diff = {
                keymaps = {
                    next_hunk = "J",
                    previous_hunk = "K",
                    stage = "s", -- Stage hunk in normal mode, stage selected lines in visual mode
                },
            },
            difftool = {
                auto_display_on = true,
            },
            git_filetype = {
                keymaps = {
                    show_details = "<enter>", -- Show details for item under cursor
                },
            },
            log = {
                keymaps = {
                    checkout = "c", -- Checkout commmit under cursor
                    commit_details = "<enter>",
                    commit_info = "i",
                    diff_commit_against_head = "d",
                    pull = "p",
                    push = "<leader>p",
                    rebase = "rb", -- Interactive rebase from current commit to commit under cursor
                    reset = "rs", -- Reset to commit under cursor
                    revert = "rv", -- Revert commit under cursor, but don't commit changes
                    revert_and_commit = "rV", -- Revert commit under cursor, and commit the revert
                    show = "s",
                },
            },
            open_files = {
                keymaps = { -- When available, these open file under cursor in various UIs
                    open_in_current_window = "ow",
                    open_in_horizontal_split = "oh",
                    open_in_new_tab = "ot",
                    open_in_vertical_split = "ov",
                },
            },
            reflog = {
                keymaps = {
                    checkout = "c",
                    commit_details = "<enter>",
                    commit_info = "i",
                    show = "s",
                },
            },
            stash = {
                auto_display_on = true,
                keymaps = {
                    apply = "a",
                    drop = "d",
                    pop = "p",
                    show = "<enter>",
                },
            },
            stash_popup = {
                keymaps = {
                    stash_all = "a",
                    stash_staged = "s",
                },
            },
            status = {
                auto_display_on = true,
                keymaps = {
                    commit_popup = "c",
                    diff_file = "D",
                    edit_file = "<enter>", -- Close status UI and navigate to file under cursor
                    enter_staging_area = "<leader>s", -- In staging area you can (un)stage hunks or lines
                    pull = "p",
                    push = "<leader>p",
                    restore = "d", -- Display a popup with options for `git restore`
                    stage = "s", -- (un)stage file under cursor
                    stage_all = "a",
                    stash_popup = "S",
                },
            },
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

Improvements to the documentation are also welcome. Additionally, there are templates for asking questions, bug reports, and feature requests, all which are also good ways to contribute.

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

Run tests based on tags
```sh
busted --helper spec/minimal_init.lua . --tags=simple
```

We might not have any tagged tests, but to make one, set up
as test like this:
```lua
describe("User management controls #simple", function ()...
```

# Tracking Updates
See [doc/news.txt](doc/news.txt) for updates.

# Credits
Thank you to Samuel Williams and the maintainers of [nvim-unception](https://github.com/samjwill/nvim-unception).
Some code from that plugin was vendored into Ever to support preventing nested nvim sessions when opening an editor
from within an nvim terminal, e.g. the commit editor when running `:G commit`.

Thank you to Isak Buhl-Mortensen and the maintainers of [gitgraph.nvim](https://github.com/isakbm/gitgraph.nvim).
This plugin was vendored into Ever to support a beautiful graph for `:G log --graph`.

Thanks to Tim Pope and the maintainers of [vim-fugitive](https://github.com/tpope/vim-fugitive), an absolutely incredible vim 
plugin that _heavily_ influenced Ever.

Thanks to Jesse Duffield and the maintainers of [lazygit](https://github.com/jesseduffield/lazygit), a sick terminal
git TUI that also heavily influenced Ever.

Thanks to Jonas Bernoulli, Kyle Meyer, and the maintainers of [magit](https://github.com/magit/magit). I've never
personally used it, but its wonderful documentation inspired both some features and design priniciples of Ever.
