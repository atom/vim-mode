## Implemented Operators

* [Delete](http://vimhelp.appspot.com/change.txt.html#deleting)
  * `dw` - with a motion
  * `3d2w` - with repeating operator and motion
  * `dd` - linewise
  * `d2d` - repeated linewise
  * `D` - delete to the end of the line
* [Change](http://vimhelp.appspot.com/change.txt.html#c)
  * `cw` - deletes the next word and switches to insert mode.
* [Yank](http://vimhelp.appspot.com/change.txt.html#yank)
  * `yw` - with a motion
  * `yy` - linewise
  * `y2y` - repeated linewise
  * `"ayy` - supports registers (only named a-h, pending more
    advanced atom keymap support)
  * `Y` - linewise
* [Put](http://vimhelp.appspot.com/change.txt.html#p)
  * `p` - default register
  * `P` - pastes the default register before the current cursor.
  * `"ap` - supports registers (only named a-h, pending more
    advanced atom keymap support)
* [Join](http://vimhelp.appspot.com/change.txt.html#J)
  * `J` - joins the current line with the immediately following line.
