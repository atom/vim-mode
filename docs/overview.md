## Overview

* There are only currently two modes, command mode and insert mode.
* Motions have repeat support, `d3w` will delete three words.
* Insert mode can be entered using `i`, `I`, `a`, `A`, `o`, or `O`.
* Registers are a work in progress
  * What Exists:
    * `a-z` - Lowercase named registers
    * `*`, `+` - System clipboard registers, although there's no distinction between the two currently.
    * `%`   - Current filename read-only register
    * `_` - Blackhole register
  * What Doesn't Exist:
    * default buffer doesn't yet save on delete operations.
    * `A-Z` - Appending via upper case registers
* Setting `wrapLeftRightMotion` acts like VIM's whichwrap=h,l,<,>
