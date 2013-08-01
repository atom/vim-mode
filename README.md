## Vim-mode

Provides vim support for Atom.

### Installing

Use the Atom package manager, which can be found in the preferences
dialog.

### Current Status

This package is far from finished (vim wasn't built in a day). The
current focus is to ensure that an appropriate model is in place so that
operators and motions can be incrementally added by the users who find
them useful as no one person uses all of vim's functionality.

#### Implemented Motions

* w
* b
* h,j,k,l
* }

#### Implemented Operators

* d
* i

#### Other features

* Insert and command mode.
* Motions can be repeated like so, 'd3w' will delete three words.

### Development

See CONTRIBUTING.md
