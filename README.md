## Vim Mode package

:rotating_light: Package is experimental :rotating_light:

Provides vim modal control for Atom, ideally blending the best of vim
and Atom.

### Installing

Use the Atom package manager, which can be found in the Settings view or
run `apm install vim-mode` from the command line.

### Current Status

This package is far from finished (vim wasn't built in a day). The
current focus is to ensure that an appropriate model is in place so that
operators and motions can be incrementally added by the users who find
them useful as no one person uses all of vim's functionality.

### Future Work (in rough order)

* Visual mode
  * ~~Characterwise~~
  * ~~Linewise~~
  * Blockwise
* Support for marks (including \`.)
* Support for `q` and `.`
  * There is now partial support for `.`, full support is pending atom/atom#962
* ~~Differentiate between 0 for repetition and 0 for motion.~~
* Block backspace in command mode.
  * Block `ctrl-d` in insert mode.
* More advanced keymap to support `iw` motion.
  * Support for `f` and `t`
  * Handle `g{line}` and `gg`

### Documentation

* [Overview](https://github.com/atom/vim-mode/blob/master/docs/overview.md)
* [Motions](https://github.com/atom/vim-mode/blob/master/docs/motions.md)
* [Operators](https://github.com/atom/vim-mode/blob/master/docs/operators.md)
* [Commands](https://github.com/atom/vim-mode/blob/master/docs/commands.md)
* [Splits](https://github.com/atom/vim-mode/blob/master/docs/splits.md)
* [Scrolling](https://github.com/atom/vim-mode/blob/master/docs/scrolling.md)

### Development

* Create a branch with your feature/fix.
* Add a spec (take inspiration from the ones that are already there).
* If you're adding a command be sure to update the appropriate file in
  `docs/`
* Create a PR.

When in doubt, open a PR earlier rather than later so that you can
receive feedback from the community.

See [the contribution guide](https://github.com/atom/vim-mode/blob/master/CONTRIBUTING.md).
