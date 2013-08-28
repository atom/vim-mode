## Implemented Operators

* [Delete](http://vimhelp.appspot.com/change.txt.html#deleting)
  * `vwd` - works in visual mode
  * `dw` - with a motion
  * `3d2w` - with repeating operator and motion
  * `dd` - linewise
  * `d2d` - repeated linewise
  * `D` - delete to the end of the line
* [Change](http://vimhelp.appspot.com/change.txt.html#c)
  * `vwc` - works in visual mode
  * `cw` - deletes the next word and switches to insert mode.
  * `cc` - linewise
  * `c2c` - repeated linewise
  * `C` - change to the end of the line
* [Yank](http://vimhelp.appspot.com/change.txt.html#yank)
  * `vwy` - works in visual mode
  * `yw` - with a motion
  * `yy` - linewise
  * `y2y` - repeated linewise
  * `"ayy` - supports registers (only named a-h, pending more
    advanced atom keymap support)
  * `Y` - linewise
* Indent/Outdent
  * `vw>` - works in visual mode
  * `>>` - indent current line one level
  * `<<` - outdent current line one level
* [Put](http://vimhelp.appspot.com/change.txt.html#p)
  * `p` - default register
  * `P` - pastes the default register before the current cursor.
  * `"ap` - supports registers (only named a-h, pending more
    advanced atom keymap support)
* [Join](http://vimhelp.appspot.com/change.txt.html#J)
  * `J` - joins the current line with the immediately following line.
