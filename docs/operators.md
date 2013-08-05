## Implemented Operators

* [Delete](http://vimhelp.appspot.com/change.txt.html#deleting)
  * `dw` - with a motion
  * `3d2w` - with repeating operator and motion
  * `dd` - linewise
  * `d2d` - repeated linewise
  * `D` - delete to the end of the line
* [Yank](http://vimhelp.appspot.com/change.txt.html#yank)
  * `yw` - with a motion
  * `yy` - linewise
  * `y2y` - repeated linewise
  * `"ayy` - supports registers (only named a-h, pending more
    advanced atom keymap support)
* [Put](http://vimhelp.appspot.com/change.txt.html#p)
  * `p` - default register
  * `"ap` - supports registers (only named a-h, pending more
    advanced atom keymap support)
