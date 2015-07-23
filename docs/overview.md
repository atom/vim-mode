## Overview

* There are only currently two modes, normal mode and insert mode.
* Motions have repeat support, `d3w` will delete three words.
* Insert mode can be entered using `i`, `I`, `a`, `A`, `o`, or `O`.
  * The following commands are supported in insert mode:
    * `ctrl-y` to copy the character right above the cursor
    * `ctrl-e` to copy the character right below the cursor (**disabled by default**, see note&nbsp;1 below)
* Replace mode can be entered using `R`
  * Limitations:
    * If repeating with `.` gets a bit confused (e.g. by multiple cursors or when more than one line was typed), please report it with steps to reproduce if you can.
* Registers are a work in progress
  * What Exists:
    * `a-z` - Named registers
    * `A-Z` - Appending to named registers
    * `*`, `+` - System clipboard registers, although there's no distinction between the two currently.
    * `%`   - Current filename read-only register
    * `_` - Blackhole register
  * What Doesn't Exist:
    * default buffer doesn't yet save on delete operations.
* Setting `wrapLeftRightMotion` acts like VIM's whichwrap=h,l,<,>


#### Notes

1. To enable the VIM key binding `ctrl-e` to copy the character right below the cursor, please put this in your `keymap.cson`:

```
'atom-text-editor.vim-mode.insert-mode':
  'ctrl-e': 'vim-mode:copy-from-line-below'
```
