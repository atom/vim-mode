## Vim Mode package [![Build Status](https://travis-ci.org/atom/vim-mode.svg?branch=master)](https://travis-ci.org/atom/vim-mode)

Provides vim modal control for Atom, ideally blending the best of vim
and Atom.

### Installing

Use the Atom package manager, which can be found in the Settings view or
run `apm install vim-mode` from the command line.

### Current Status

Sizable portions of Vim's command mode work as you'd expect, including
many complex combinations. Even so, this package is far from finished (Vim
wasn't built in a day).

Currently, vim-mode requires soft line wraps to be disabled, and has some issues
with international keyboard layouts.

If there's a feature of Vim you're missing, it might just be that you use it
more often than other developers. Adding a feature can be quick and easy. Check
out the [closed pull requests](https://github.com/atom/vim-mode/pulls?direction=desc&page=1&sort=created&state=closed)
to see examples of community contributions. We're looking forward to yours, too.

### Documentation

* [Overview](https://github.com/atom/vim-mode/blob/master/docs/overview.md)
* [Motions](https://github.com/atom/vim-mode/blob/master/docs/motions.md)
* [Operators](https://github.com/atom/vim-mode/blob/master/docs/operators.md)
* [Windows](https://github.com/atom/vim-mode/blob/master/docs/windows.md)
* [Scrolling](https://github.com/atom/vim-mode/blob/master/docs/scrolling.md)

### Development

* Create a branch with your feature/fix.
* Add a spec (take inspiration from the ones that are already there).
* If you're adding a command be sure to update the appropriate file in
  `docs/`
* Create a PR.

When in doubt, open a PR earlier rather than later so that you can receive
feedback from the community. We want to get your fix or feature included as much
as you do.

See [the contribution guide](https://github.com/atom/vim-mode/blob/master/CONTRIBUTING.md).
