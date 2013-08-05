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

* Implement `J` operator.
* Implement `a` command.
* Implement `>>` and `<<` operators.
* Implement `ctrl-u` and `ctrl-d`.
* Implement `0` motion.
* Undo/redo bindings.
* Block backspace in command mode.
* More advanced keymap to support `iw` motion.

### Documentation

* [Overview](docs/overview.md)
* [Motions](docs/motions.md)
* [Operators](docs/operators.md)

### Development

See [the contribution guide](CONTRIBUTING.md).
