## Vim-mode

Provides vim modal control to Atom and hopefully the successor to the
[other vim plugin](https://github.com/atom/vim)

### Installing

Use the Atom package manager, which can be found in the preferences
dialog.

### Current Status

This package is far from finished (vim wasn't built in a day). The
current focus is to ensure that an appropriate model is in place so that
operators and motions can be incrementally added by the users who find
them useful as no one person uses all of vim's functionality.

### Future Work (in rough order)

* `s` operator
* `e` motion
* Visual mode
* Support for marks (including \`.)
* Differentiate between 0 for repetition and 0 for motion.
* Proper undo/redo stack.
* Block backspace in command mode.
  * Block `ctrl-d` in insert mode.
* More advanced keymap to support `iw` motion.
  * Support for 'f' and 't'
  * Handle `g{line}` and `gg`
  
### Documentation

* [Overview](docs/overview.md)
* [Motions](docs/motions.md)
* [Operators](docs/operators.md)

### Development

**Important** you'll need to be running a locally built version of Atom to
run tests.

See [the contribution guide](CONTRIBUTING.md).
