## Vim Mode package [![Build Status](https://travis-ci.org/atom/vim-mode.svg?branch=master)](https://travis-ci.org/atom/vim-mode)

Provides Vim modal control for Atom, blending the best of Vim and Atom.

### Current Status - DEPRECATED in favor of [vim-mode-plus](https://github.com/t9md/atom-vim-mode-plus)

We're not developing new features on this package right now, though we still want to fix regressions and keep it working. A lot of people now use vim-mode-plus which is very well maintained.

Sizable portions of Vim work as you'd expect, including many complex combinations.

[prs]: https://github.com/atom/vim-mode/pulls?direction=desc&page=1&sort=created&state=closed
[issues]: https://github.com/atom/vim-mode/issues

### Installing

Use the Atom package manager, which can be found in the Settings view or run `apm install vim-mode` from the command line.

### Issues and Limitations

If you want the Vim ex line (for `:w`, `:s`, etc.), you can try [ex-mode](https://atom.io/packages/ex-mode)
which works in conjunction with this plugin.

Currently, vim-mode has some issues with non-US keyboard layouts. If you are using a keyboard layout which *isn't* American and having problems, try installing [keyboard-localization](https://atom.io/packages/keyboard-localization).

### Development

* Create a branch with your feature/fix.
* Add a spec (take inspiration from the ones that are already there).
* Create a PR.

When in doubt, open a PR earlier rather than later and join [#vim-mode](https://atomio.slack.com/messages/vim-mode/) on the [Atom Slack](http://atom-slack.herokuapp.com/) so that you can receive
feedback from the community. We want to get your fix or feature included as much
as you do.

See [the contribution guide](https://github.com/atom/vim-mode/blob/master/CONTRIBUTING.md).
