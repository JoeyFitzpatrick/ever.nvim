# Roadmap to Beta

At the time of this writing, Ever.nvim is in alpha. This document shows what features, bug fixes, and improvements are needed for Ever.nvim to get to beta.

## Features

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

That kind of stuff. Not sure what's feasible, but it would be nice to be able to have this feature, especially for things that aren't 
covered by `reflog`, such as undoing `git restore`.

### Visual mode commands
The impetus for this is `:G log -L`. In visual mode, this should automatically pass in the line numbers and file name.
However, there should be some thought into if there are other commands that could benefit from visual mode. For instance,
`:G log -S` automatically using visually selected text (not lines) would be nice.

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

## Improvements

### Make Neovim opened in nested buffer use the current session
For instance, if `:G commit` is used, this should open the commit editor in the current Neovim instance.
Currently, it opens another instance of Neovim inside the terminal, inside the original Neovim instance (aka nested sessions).

I have a different project that achieved this, I just need to port over that code.

### Diff highlight engine

I'm not a big fan of the built-in diff highlighting. It would be nice to have something closer to [delta](https://github.com/dandavison/delta).
This would allow for using regular buffers for diffs in all cases, instead of terminal buffers, which would be a big win for functionality.

### Git pull can't rebase multiple branches
Sometimes when using the `git pull` mapping in a UI, instead of pulling, there is an error that says `can't rebase onto multiple branches`.
This usually goes away after pulling a second or third time. It would be nice if this just didn't happen at all.

### Status UI set cursor to first file
Currently, the status UI just puts the cursor on the first line, even if there are files. This means the user has to move the cursor down twice
just to start seeing file diffs. The cursor should automatically be moved to the first file:
* if there is a file, and
* if the cursor isn't already at or past the first file.

### Git integration tests
The thought here is that integration tests could help ensure that our functions produce the correct git state, given some current state.
This could be pretty powerful. Would probably look like:
* A script to set up git repo for various states
* Teardown script
* Be able to call these before/after each test run
