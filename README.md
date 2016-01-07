## Vim Mode package [![Build Status](https://travis-ci.org/atom/vim-mode.svg?branch=master)](https://travis-ci.org/atom/vim-mode)

Provides Vim modal control for Atom, blending the best of Vim and Atom.

### Current Status

Sizable portions of Vim work as you'd expect, including many complex combinations.
Even so, this package is far from finished (Vim wasn't built in a day).

If there's a feature of Vim you're missing, it might just be that you use it more often than other developers. Adding a feature can be quick and easy. Check out the [closed pull requests][prs] to see examples of community contributions, and look at the [issues][issues] to see if anyone has already solved your problem.

[prs]: https://github.com/atom/vim-mode/pulls?direction=desc&page=1&sort=created&state=closed
[issues]: https://github.com/atom/vim-mode/issues

### Installing

Use the Atom package manager, which can be found in the Settings view or run `apm install vim-mode` from the command line.

### Issues and Limitations

If you want the Vim ex line (for `:w`, `:s`, etc.), you can try [ex-mode](https://atom.io/packages/ex-mode)
which works in conjunction with this plugin.

Currently, vim-mode has some issues with non-US keyboard layouts. If you are using a keyboard layout which *isn't* American and having problems, try installing [keyboard-localization](https://atom.io/packages/keyboard-localization).

#### Double-key Keymaps in Insert Mode

Because the letter keys are typically used to insert characters into the buffer in Insert Mode, binding key combinations like `jj` or `jk` to stand in for `ESC` can be tricky. For example, while the following mapping in `keymap.cson` file will work, you'll notice that the first character doesn't appear on screen until another key is pressed or the keymap wait delay expires (see [KeymapManager::partialMatchTimeout](https://atom.io/docs/api/v1.3.2/KeymapManager)).

```coffeescript
# This works, but the delay in seeing the first character appear
# is inconsistent with Vim and can be jarring to the user.
'atom-text-editor.vim-mode.insert-mode':
  'j k': 'vim-mode:activate-normal-mode'
```

An alternative approach proposed in [issue #334 "Remapping ESC"](https://github.com/atom/vim-mode/issues/334#issuecomment-85603175) requires slightly more configuration, but emulates Vim's behavior and eliminates the delay. First, define a function in `init.coffee` which activates Normal Mode if the character immediately before the cursor is the _first_ character in our desired keymapping:

```coffeescript
# init.coffee
atom.commands.add 'atom-text-editor', 'activate-normal-mode-if-preceded-by-j': (e) ->
  targetChar = "j" # This should be the FIRST char in your desired mapping
  editor = @getModel()
  pos = editor.getCursorBufferPosition()
  range = [pos.traverse([0,-1]), pos]
  lastChar = editor.getTextInBufferRange(range)
  if lastChar is targetChar
    editor.backspace() # remove the 'j' character from the buffer
    atom.commands.dispatch(e.currentTarget, 'vim-mode:activate-normal-mode')
  else
    e.abortKeyBinding()
```

Now, we just need to bind a single key (the _second_ character in our desired mapping) to the command we just created:

```coffeescript
# keymap.cson
# Bind 'jk' to ESC. Specifically, while in Insert Mode, bind 'k' to a function defined
# in init.coffee that activates Normal Mode if the character immediately before the cursor is 'j'.
'atom-text-editor.vim-mode.insert-mode':
  'k': 'activate-normal-mode-if-preceded-by-j'
```

This technique can be adapted to any combination of two keys, such as `jj`, `jk` or—better yet—`kj` (as [Dijkstra](https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm) surely would have preferred!)

_Note that changes to your `init.coffee` are only picked up upon restarting Atom._

_Caveat:_ In order to enter the mapped characters into a buffer (e.g., typing 'Dijkstra' above), you must first enter those characters separated by a space and then then delete it. This is inconsistent with Vim's behavior, but fortunately it very rarely happens outside of writing documentation about this specific feature!

### Development

* Create a branch with your feature/fix.
* Add a spec (take inspiration from the ones that are already there).
* Create a PR.

When in doubt, open a PR earlier rather than later and join [#vim-mode](https://atomio.slack.com/messages/vim-mode/) on the [Atom Slack](http://atom-slack.herokuapp.com/) so that you can receive
feedback from the community. We want to get your fix or feature included as much
as you do.

See [the contribution guide](https://github.com/atom/vim-mode/blob/master/CONTRIBUTING.md).
