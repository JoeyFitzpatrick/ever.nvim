# Roadmap to Beta
At the time of this writing, Ever.nvim is in alpha. This document shows what features, bug fixes, and improvements are needed for Ever.nvim to get to beta.

## Features

### Display files in a tree
In all UIs that display files, we currently display all files in a flat structure; each file takes up one line. It would be great to be able to display files in a tree instead. This should be config driven. This should be doable for most, if not all, UIs. The first one to tackle would be the status UI.

### Display descriptions for mapping under cursor in popups and help float
I like the idea of making this a one-key mapping, e.g. pressing `?` shows a description of the keymap under the cursor.

I'd also be open to making this happen automatically on cursor move. But I wonder if this would look cluttered.

### Branch spin-off mappings in branch UI
This is a [magit feature](https://magit.vc/manual/magit/Branch-Commands.html#index-b-s).

### Undo
Not well thought out, but the idea is that we could undo some operations:
* undo a merge commit (just reset to the commit before the merge probably)
* undo `git restore`
* undo deleting a branch
* re-stash changes that were popped off the stash list

That kind of stuff. Not sure what's feasible, but it would be nice to be able to have this feature, especially for things that aren't covered by `reflog`, such as undoing `git restore`.

### Worktree UI
Self-explanatory, would be nice to have a UI around worktrees.

### Time machine
This feature would be similar to [git-timemachine](https://github.com/emacsmirror/git-timemachine) from emacs. Would probably work like this:
1. Keymaps to move to next/previous version of file.
1. A split that shows the commit details for the commit that time machine is using to show the file.
1. Be able to toggle the split. Config drives whether it is on or off by default.

Need to decide on the API for this. Probably would be better not to make it a `:G` command, just to keep that clean (just git commands).
So maybe a plug mapping?

### Git restore hunk/lines/file from previous commit
In a file from a previous commit, be able to:
* visually select lines to restore
* restore the entire file

In a git patch, be able to do the above, as well as:
* restore a single hunk

### Allow users to create custome command mappings
Users should be able to create their own keymaps for different UIs. This can be done in a couple of ways:
1. In the config, allow specifying a map/function combination. For instance:
```lua
    commit = {
        keymaps = {
            p = function()
                -- Ever lua API used here?
            end
        }
    }
```
A potential pitfall here is that we currently map from command to key, not key to map. So we'd either need to invert existing keymaps, or support current mappings but allow new ones to be inverted.
2. Create autocmds for different UIs, so that keymaps could be created for a given UI as part of its autocmd. Not a huge fan of this approach, but there might be other reasons to create these autocmds anyways.

## Improvements

### Diff highlight engine
I'm not a big fan of the built-in diff highlighting. It would be nice to have something closer to [delta](https://github.com/dandavison/delta). This would allow for using regular buffers for diffs in all cases, instead of terminal buffers, which would be a big win for functionality.

### Git pull can't rebase multiple branches
Sometimes when using the `git pull` mapping in a UI, instead of pulling, there is an error that says `can't rebase onto multiple branches`. This usually goes away after pulling a second or third time. It would be nice if this just didn't happen at all.

### Status UI set cursor to first file
Currently, the status UI just puts the cursor on the first line, even if there are files. This means the user has to move the cursor down twice just to start seeing file diffs. The cursor should automatically be moved to the first file:
* if there is a file, and
* if the cursor isn't already at or past the first file.

### Git integration tests
The thought here is that integration tests could help ensure that our functions produce the correct git state, given some current state. This could be pretty powerful. Would probably look like:
* A script to set up git repo for various states
* Teardown script
* Be able to call these before/after each test run

### Git branch --all is sluggish
It probably just needs to switch to streaming lines in.

### Git log -S with multiline visual selection
It would be awesome if using `:G log -S` from visual mode worked with a multiline selection. One way this _could_ work is to use concepts from [this blog post](https://hoelz.ro/blog/applying-gits-pickaxe-option-across-multiple-lines-of-yaml-using-textconv). The gist of it is:
* create a script that replaces new lines in a diff with a string like `\n`
* pass this to the `log` command using the `-c` flag
* pass the `--pickaxe-regex` option to the command to ignore any whitespace changes between lines

This is hilariously over-the-top, but it would be pretty cool.

### Git log --graph
Make `:G log --graph` highlight the graph characters and actually fetch the commits for keymaps. There's a plugin that exists that we could make an integration for, or we could just do a really simple version ourselves.

### Git diff keymaps
When using a command like `:G show abc123`, there are keymaps that allow for opening files and diffs for a the given commit. It would be nice to have the same keymaps for `:G diff abc123`. For `show`, there are maps to open a file at the given commit, or at the commit _before_ the given commit. For `diff`, we'd probably want to use that, but also support a commit range or multiple given commits, so in the case of `:G diff commit1 commit2`, the "previous" file would be `commit1`.

### Quiet commands
In git, many commands take a `--quiet` flag that surpresses informational messages. It would be nice to have this work for `:G` commands, so running a command like `:G checkout some-branch --quiet` should not open a split, for instance.
