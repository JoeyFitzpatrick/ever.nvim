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

Note: lazy loading is handled internally, so it is not required to lazy load Ever. It loads in less than 1ms on my machine. With that being said, if you really want to lazy load Ever, you should be able to lazy load it however you normally lazy load plugins.


# Configuration
(These are default values)

<!-- TODO: (you) - Remove / Add / Adjust your configuration here -->

- [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
    "JoeyFitzpatrick/ever.nvim",
    config = function()
        vim.g.ever_configuration = {
            -- TODO: add config here
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

# Keymaps for Raw Git Output
When a command outputs raw git output (for example, `:G log -p`), a keymap is created to show details for the item under the cursor. 
By default, this is `<enter>`. Some details:
* If the current line is a filepath, e.g. `--- a/lua/ever/_ui/keymaps/git_filetype_keymaps.lua`, it opens the file at that revision. Lines that start with `---` are the revision
before the commit associated with this change, lines that begin with `+++` are the revision at that commit.
* If the line begins with `diff` or `@@`, the previous and next versions of the file, relative to that commit, are opened in a vim diff.
* Otherwise, the commit is opened in the commit details UI.

It's worth noting that this functionality already exists in vim-fugitive, with some minor differences.

# Special Commands

Some commands that are often used, or are normally cumbersome to use, are handled differently than just running the command in terminal mode. This typically means opening a buffer that serves as a UI for the command. Here are the special commands:
* `git branch`
* `git log`
* `git commit`
* `git blame`
* `git stash list`
* `git show`
* `git {command} -h`
* `git {command} --help`

Note that for any command that brings up a UI:
* You can close the UI by pressing `q`, in addition to the normal methods, such as `:q`
* The jumplist still works like normal `<C-i>` and `<C-o>`
* You can view keymaps by pressing `g?`

##
Using the `:G` command renders a home ui, that will display some status info. This includes the git status of all changed files, a diff split to display these changes, and some keymaps to manipulate these files, such as staging/unstaging them. Use `h` and `l` to then display the UI for  `git branch`, `git log`, and `git stash`, all of which are further detailed below.

### Staging Area
By default, pressing `<leader>s` in the status tab of the home UI will open the staging area. This is the same as running `:G difftool` with no arguments. The main features here are seeing what changes are staged, what changes are unstaged, navigating between hunks, (un)staging visually selected lines, and (un)staging hunks.

Note that you can select lines with either visual mode or linewise-visual mode, and use the "stage" keymap (`s` by default) to (un)stage selected lines. If you want to (un)stage single lines at a time, you can use `vs`, to visually select a line and immediately (un)stage it.

## Difftool
Passing commit(s) to Ever's `difftool` command, e.g. `:G difftool abc123` or `:G difftool abc123..def456`, will open a UI that allows for seeing the diff introduced
by a commit, or the diff between two commits. Note that if a commit range is given, e.g. `abc123..def456`, using the open-file keymaps will use the latter commit.
So in this example, using `oh` to open a file in a horizontal split would use commit `def456`.

## Branch
`:G` commands that display a list of branches, such as `:G branch`, `:G branch --all`, `:G branch --merged`, and so on, bring up a branch UI, from which keymaps can be used to view commits, rename branches, merge branches, etc. The [default configuration section](#default-configuration) shows every keymap, as does pressing `g?` in the branch UI.

G branch commands that do not display a list of branches, such as `:G branch --delete`, run the command in terminal mode, as if it were a non-special command.

## Log
`:G` log commands will typically open a UI. The [default configuration section](#default-configuration) shows every keymap, as does pressing `g?` in the log UI.

When using the `:G log` command without arguments, a default [`--pretty`](https://git-scm.com/docs/pretty-formats) option is passed to the `log` command to change how the output looks. Passing any arguments to `:G log` causes this `--pretty` option to not be added to the `log` command.

### Log -L

`:G` log has a `-L` flag, as shown [in the docs](https://git-scm.com/docs/git-log#Documentation/git-log.txt--Lltstartgtltendgtltfilegt). This can be used to see the commits that changed just the line numbers given, e.g. `git log -L20,40:example.lua`, to see just the commits that changed lines from 20 to 40 in `example.lua`. In many cases, this can be an extremely useful way to search for changes, as opposed to running something like `git log --follow example.lua`, which could show commits that made changes that you don't care about. With Ever, if you make a visual selection and run `:'<,'>G log`, without passing line numbers or a file name, it will pass the line numbers and file name automatically to the git command, making it much more convenient to use.

## Commit
`:G` commit will open an editor to create the commit message when that message is not passed to the command, e.g. `git commit` (no message, opens the editor) vs `git commit -m "some message"` (does not open the commit message editor). When the commit message editor is opened, Ever opens it in the current Neovim instance. You can write and quit the editor (`:wq`) to apply the message, or simply close the editor without saving to abort the commit due to an empty commit message. If the commit message editor doesn't need to open, the command will just run in terminal mode like most other commands.

## Blame
Like vim-fugitive, running `:G blame` will open a blame window to the left, that uses `:h scrollbind` to sync with with the opened file. From there, many of the keymaps for the commit UI also work in the blame UI. The [default configuration section](#default-configuration) shows every keymap, as does pressing `g?` in the blame UI.

## Stash List
Running `:G stash list` will open a UI, in which you can view, pop, apply, and drop stashes. Other stash commands, like `:G stash show`, run in terminal mode like most other commands.

## Show
Running `:G show` commands will just open their output in the current window. Not amazingly helpful, but sometimes nice when that's what you need. You can close this with `q` like other Ever buffers.

## Help Commands
Running a git help command, such as `:G commit -h` or `:G log --help`, will open that help file in the current window. This way, you can use your normal vim navigation to move through the docs, versus opening a pager. You can close it by pressing `q` to return to your last buffer.

# UI Management (Tabs, Windows, Buffers)
When Ever opens a UI, this will typically either open a new buffer in the current window, or open a new window in a split. In either case, the window can be closed with the `q` keymap, which will return you to the last non-Ever buffer that was open.

If you want to open something in a non-standard ui, this is supported natively via command mode:
Open `G status` in a left split instead of a full window: `split | G status`
Open `G branch` in a right split instead of a full window `rightbelow vsplit | G branch`
Note that this functionality can be used in both command mode and in keymaps.

### Auto-display
Some UIs, such as the status UI, will automatically display another window in a split when moving the cursor in the main window.
* The status UI displays a diff for the file under the cursor
* The commit details UI displays a diff for the file under the cursor for the given commit
* The stash UI displays a diff for the entire stash under the cursor

To toggle the auto-display, enter the toggle keymap. This is `<tab>` by default, and can be changed in the configuration. You can find this keymap by pressing the `g?` keymap.

# Plug mappings
Ever provides some plug mappings, so you can conveniently create your own mappings for some actions if you want. To use such a mapping, you can do something like this:

```lua
-- Keymap to display the commit popup
vim.keymap.set("n", "<leader>gc", "<Plug>(Ever-commit-popup)")
```

### Merge conflict mappings
Ever doesn't have an integrated merge conflict resolution solution currently, so in the meantime, we have these mappings:
<Plug>(Ever-resolve-base): when the cursor is on a merge conflict, keep the "base" code
<Plug>(Ever-resolve-ours): when the cursor is on a merge conflict, keep the "ours" code
<Plug>(Ever-resolve-theirs): when the cursor is on a merge conflict, keep the "theirs" code
<Plug>(Ever-resolve-all): when the cursor is on a merge conflict, keep all code

### Popup mappings
<Plug>(Ever-commit-popup): display the commit popup
<Plug>(Ever-stash-popup): display the stash popup


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
