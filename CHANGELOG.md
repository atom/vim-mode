## 0.6.0 - Updates
* Implemented '.' operator, thanks to @bhuga
* Fix putting at the end of lines, thanks to @bhuga
* Compatibility with Atom 0.50.0

## 0.5.0 - Updates
* Switches apm db to cloudant from iriscouch

## 0.4.0 - Updates
* Compatibilty with Atom 26

## 0.3.0 - Visual and Collaborative
* Compatiblity with atom 0.21
* Characterwise visual-mode!
* System copy and paste are now linked to the `*`
* Implement `A` operator
* Bugfixes concerning `b` and `P`

## 0.2.3 - Not solo anymore

* Major refactoring/cleanup/test speedup.
* Added 'S' command.
* Added 'C' operator.
* Proper undo/redo transactions for repeated commands.
* Enhance 'G' to take line numbers.
* Added 'Y' operator.
* Added 'ctrl-c' to enter command mode.

## 0.2.2

* Added 's' command.
* Added 'e' motion.
* Fixed 'cw' removing trailing whitepsace
* Fixed cursor position for 'dd' when deleting blank lines

## 0.2.1

* Added the `c` operator (thanks Yosef!)
* Cursor appears as block in command mode and blinks when inserting (thanks Corey!)
* Delete operations now save deleted text to the default buffer
* Implement 'gg' and 'G' motions
* Implement 'P' operator
* Implement 'o' and 'O' commands

## 0.2.0

* Added yank and put command with support for registers
* Added '$' and '^' motions
* Fixed repeats for commands and motions, ie `d2d` works as expected.
* Implemented `D` to delete through the end of the line.
* Implemented `>>` and `<<` indent and outdent commands.
* Implemented `J`.
* Implemented `a` to move cursor and enter insert mode.
* Add basic scrolling using `ctrl-u` and `ctrl-d`.
* Add basic undo/redo using `u` and `ctrl-r`. This needs to be improved so it
  understands vim's semantics.

## 0.1.0

* Nothing changed, used this as a test release to understand the
  publishing flow.

## 0.0.1

* Initial release, somewhat functional but missing many things.
