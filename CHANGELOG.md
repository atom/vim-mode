## HEAD

## 0.61

* Implemented '(' and ')' sentence motion operators - @jonasws

## 0.60

* Fixed an issue where commands that took one character of input didn't
  work with characters composed via IME - @jacekkopecky
* Fixed an issue where the '%' motion would select the wrong range
  when moving backwards - @jacekkopecky

## 0.59

* Fixed an issue where normal Atom commands and mouse drags couldn't
  move the cursor to the end of a line - @jacekkopecky

## 0.58

* Fixed repetition of commands executed in visual mode - @jacekkopecky
* Fixed repetition of indentation commands - @mleeds95
* Fixed `cc` command's behavior on the file's only line @jacekkopecky
* Fixed key-binding for return-from-tag - @bronson
* Implemented shared 'f' and 't' state between editors - @jacekkopecky
* Added insert-mode commands for copying line above and below - @jacekkopecky
* Fixed an exception when prefixing a text object with a count - @jacekkopecky
* Fixed handling of blank lines in the `ip` and `ap` text objects - @MarkusSN

## 0.57

* Added replace ('R') mode! - @jacekkopecky
* Added the `iW` and `aW` text objects! - @jacekkopecky
* Made the 't' operator behave correctly when the cursor was already on the  
  searched  character - @jacekkopecky
* Fixed the position of the cursor after pasting with 'p' - @jacekkopecky

## 0.56

* Renamed 'command mode' to 'normal mode' - @coolwanglu

## 0.55

* Fixed indentation commands so that they exit visual mode - @bronson
* Implemented horizontal scrolling commands `z s` and `z e` - @jacekkopecky

## 0.54

* Fixed an error where repeating an insertion command would not handle
  characters inserted by packages like autocomplete or bracket-matcher - @jacekkopecky

## 0.53

* Fixed an exception that would occur when using `.` to repeat in certain cases.

## 0.52

* Fixed incorrect cursor motion when exiting visual mode w/ a reversed
  selection - @t9md
* Added setting to configure the regexp used for numbers and the `ctrl-a`
  and `ctrl-x` keybindings - @jacekkopecky

## 0.50

* Fixed cursor position after `dd` command - @bronson
* Implement `ap` text-object differently than `ip` - MarkusSN

## 0.49

* Fixed an issue that caused the cursor to move left incorrectly when near
  the end of a line.

## 0.48

* Fixed usages of deprecated APIs

## 0.47

* Fixed usages of deprecated APIs - @hitsmaxft, @jacekkopecky

## 0.46

* Fixed issues with deleting when there are multiple selections - @jacekkopecky
* Added paragraph text-objects 'ip' and 'ap' - @t9md
* Fixed use of a deprecated method - @akonwi

## 0.45

* Added `ctrl-x` and `ctrl-a` for incrementing and decrementing numbers - @jacekkopecky
* Fixed the behavior of scrolling motions in visual mode - @daniloisr

## 0.44

* Fixed issue where canceling the replace operator would delete text - @jacekkopecky
* Implemented repeat search commands: '//', '??', etc - @jacekkopecky
* Fixed issue where registers' contents were overwritten with the empty string - @jacekkopecky

## 0.43

* Made '%', '\*' and '\#' interact properly with search history @jacekkopecky

## 0.42

* Fixed spurious command bindings on command mode input element - @andischerer

## 0.41

* Added ability to append to register - @jacekkopecky
* Fixed an issue where deactivation would sometimes fail

## 0.40

* Fixed an issue where the search input text was not visible - @tmm1
* Added a different status-bar entry for visual-line mode - @jacekkopecky

## 0.39

* Made repeating insertions work more correctly with multiple cursors
* Fixed bugs in `*` and `#` with cursor between words - @jacekkopecky

## 0.38

* Implemented change case operators: `gU`, `gu` and `g~` - @jacekkopecky
* Fixed behavior of repeating `I` and `A` insertions - @jacekkopecky

## 0.36

* Fixed an issue where `d` and `c` with forward motions would sometimes
  incorrectly delete the character before the cursor - @deiwin

## 0.35

* Implemented basic version of `i t` operator - @neiled
* Made `t` motion repeatable with `;` - @jacekkopecky

## 0.34

* Added a service API so that other packages can extend vim-mode - @lloeki
* Added an insert-mode mapping for ctrl-u - @nicolaiskogheim

## 0.33

* Added a setting for using the system clipboard as the default register - @chrisfarms

## 0.32

* Added setting for allowing traversal of line breaks via `h` and `l` - @jacekkopecky
* Fixed handling of whitespace characters in `B` mapping - @jacekkopecky
* Fixed bugs when using counts with `f`, `F`, `t` and `T` mappings - @jacekkopecky

## 0.31

* Added '_' binding - @ftwillms
* Fixed an issue where the '>', '<', and '=' operators
  would move the cursor incorrectly.

## 0.30

* Make toggle-case operator work with multiple cursors

## 0.29

* Fix regression where '%' stopped working across multiple lines

## 0.28

* Fix some deprecation warnings

## 0.27

* Enter visual mode when selecting text in command mode
* Don't select text after undo
* Always preserve selection of the intially-selected character in visual mode
* Fix bugs in the '%' motion
* Fix bugs in the 'S' operator

## 0.26

* Add o mapping in visual mode, for reversing selections
* Implement toggle-case in visual mode
* Fix bug in 'around word' text object

## 0.25

* Fixed a regression in the handling of the 'cw' command
* Made the replace operator work with multiple cursors

## 0.24

* Fixed the position of the cursor after certain yank operations.
* Fixed an issue where duplicate vim states were created when an editors were
  moved to different panes.

## 0.23

* Made motions, operators and text-objects work properly in the
  presence of multiple cursors.

## 0.22

* Fixed a stylesheet issue that caused visual glitches when vim-mode
  was disabled with the Shadow DOM turned on.

## 0.21

* Fix issue where search panel was not removed properly
* Updated the stylesheet for compatibility with shadow-DOM-enabled editors

## 0.20
* Ctrl-w for delete-to-beginning-of-word in insert mode
* Folding key-bindings
* Remove more deprecated APIs

## 0.19.1
* Fix behavior of ctrl-D, ctrl-U @anvyzhang
* Fix selection when moving up or down in visual line mode @mdp
* Remove deprecated APIs
* Fix interaction with autocomplete

## 0.19
* Properly re-enable editor input after disabling vim-mode

## 0.17
* Fix typo

## 0.16
* Make go-to-line motions work with operators @gittyupagain
* Allow replacing text with newlines using `r` @dcalhoun
* Support smart-case in when searching @isaachess

## 0.14
* Ctrl-c for command mode on mac only @sgtpepper43
* Add css to status bar mode for optional custom styling @e-jigsaw
* Implement `-`, `+`, and `enter` @roryokane
* Fix problem undo'ing in insert mode @bhuga
* Remove use of deprecated APIs

## 0.11.1
* Fix interaction with autocomplete-plus @klorenz

## 0.11.0
* Fix `gg` and `G` in visual mode @cadwallion
* Implement `%` @carlosdcastillo
* Add ctags keybindings @tmm1
* Fix tracking of marks when buffer changes @carlosdcastillo
* Fix off-by-one error for characterwise puts @carlosdcastillo
* Add support for undo and repeat to typing operations @bhuga
* Fix keybindings for some OSes @mcnicholls
* Fix visual `ngg` @tony612
* Implement i{, i(, and i" @carlosdcastillo
* Fix off by one errors while selecting with j and k @fotanus
* Implement 'desired cursor column' behavior @iamjwc

## 0.10.0
* Fix E in visual mode @tony612
* Implement `` @guanlun
* Fix broken behavior when enabling/disabling @cadwallion
* Enable search in visual mode @romankuznietsov
* Fix end-of-line movement @abijr
* Fix behavior of change current line `cc` in various corner cases. @jcurtis
* Fix some corner cases of `w` @abijr
* Don't hide cursor in visual mode @dyross

## 0.9.0 - Lots of new features
* Enable arrow keys in visual mode @fholgado
* Additional bindings for split pane movement @zenhob
* Fix search on invalid regex @bhuga
* Add `s` alias to visual mode @tony612
* Display current mode in the status bar @gblock0
* Add marks (m, `, ') @danzimm
* Add operator-pending mode and a single text object (`iw`) @nathansobo, @jroes
* Add an option to start in insert mode @viveksjain
* Fix weird behavior when pasting at the end of a file @msvbg
* More fixes for corner cases in paste behavior @SKAhack
* Implement * and # @roman
* Implement ~ @badunk
* Implement t and T @udp

## 0.8.1 - Small goodies
* Implement `ctrl-e` and `ctrl-y` @dougblack
* Implement `/`, `?`, `n` and `N` @bhuga
* Registers are now shared between tabs in a single atom window @bhuga
* Show cursor only in focused editor @tony612
* Docs updated with new methods for entering insert mode @tednaleid
* Implement `r` @bhuga
* Fix `w` when on the last word of a file @dougblack
* Implement `=` @ciarand
* Implement `E` motion @tony612
* Implement basic `ctrl-f` and `ctrl-b` support @ciarand
* Added `+`, `*` and `%` registers @cschneid
* Improved `^` movement when already at the first character @zenhob
* Fix off-by-one error for `15gg` @tony612

## 0.8.0 - Keep rocking
* API Fixes for Atom 0.62 @bhuga
* Add `$` and `^` to visual mode @spyc3r
* Add `0` to visual mode @ruedap
* Fix for yanking entire lines @chadkouse
* Add `X` operator @ruedap
* Add `W` and `B` motions @jcurtis
* Prevent cursor left at column 0 when switching to insert mode @adrianolaru
* Add pane switching shortcuts see #104 for details @dougblack
* Add `H`, `L` and `M` motions @dougblack

## 0.7.2 - Full steam ahead
* Leaving insert mode always moves cursor left @joefiorini
* Implemented `I` command @dysfunction
* Restored `0` motion @jroes
* Implemented `}` motion to move to previous paragraph @zenhob
* Implement `gt` and `gT` to cycle through tabs @JosephKu
* Implement visual linewise mode @eoinkelly
* Properly clear selection when return to command mode @chadkouse

## 0.7.1 - User improvements
* `ctrl-[` now activates command mode @ctbarna
* enter now moves down a line in command mode @ctbarna
* Documentation links now work on atom.io @michaeltwofish
* Backspace now moves back a space in command mode @Tarrant
* Fixed an issue where cursors wouldn't appear in the settings view.

## 0.7.0 - Updates for release
* Update contributing guide
* Update package.json
* Require underscore-plus directly

## 0.6.0 - Updates
* Implemented `.` operator, thanks to @bhuga
* Fix putting at the end of lines, thanks to @bhuga
* Compatibility with Atom 0.50.0

## 0.5.0 - Updates
* Switches apm db to buttant from iriscouch

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
* Added `S` command.
* Added `C` operator.
* Proper undo/redo transactions for repeated commands.
* Enhance `G` to take line numbers.
* Added `Y` operator.
* Added `ctrl-c` to enter command mode.

## 0.2.2

* Added `s` command.
* Added `e` motion.
* Fixed `cw` removing trailing whitepsace
* Fixed cursor position for `dd` when deleting blank lines

## 0.2.1

* Added the `c` operator (thanks Yosef!)
* Cursor appears as block in command mode and blinks when inserting (thanks Corey!)
* Delete operations now save deleted text to the default buffer
* Implement `gg` and `G` motions
* Implement `P` operator
* Implement `o` and `O` commands

## 0.2.0

* Added yank and put command with support for registers
* Added `$` and `^` motions
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
