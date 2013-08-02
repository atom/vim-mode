$ = require 'jquery'

RootView = require 'root-view'

describe "VimState", ->
  [editor, vimState] = []

  beforeEach ->
    window.rootView = new RootView
    rootView.open()
    rootView.simulateDomAttachment()
    atom.activatePackage('vim-mode', immediate: true)

    editor = rootView.getActiveView()
    editor.enableKeymap()
    vimState = editor.vimState

  keydown = (key, {element, ctrl, shift, alt, meta}={}) ->
    dispatchKeyboardEvent = (target, eventArgs...) ->
      e = document.createEvent("KeyboardEvent")
      e.initKeyboardEvent eventArgs...
      target.dispatchEvent e

    dispatchTextEvent = (target, eventArgs...) ->
      e = document.createEvent("TextEvent")
      e.initTextEvent eventArgs...
      target.dispatchEvent e

    element ||= document.activeElement
    eventArgs = [true, true, null, key, 0, ctrl, alt, shift, meta] # bubbles, cancelable, view, key, location

    canceled = not dispatchKeyboardEvent(element, "keydown", eventArgs...)
    dispatchKeyboardEvent(element, "keypress", eventArgs...)
    if not canceled
       if dispatchTextEvent(element, "textInput", eventArgs...)
         element.value += key
    dispatchKeyboardEvent(element, "keyup", eventArgs...)

  describe "initialize", ->
    it "puts the editor in command-mode initially", ->
      expect(editor).toHaveClass 'vim-mode'
      expect(editor).toHaveClass 'command-mode'

  describe "command-mode", ->
    it "stops propagation on key events would otherwise insert a character", ->
      keydown('\\', element: editor[0])
      expect(editor.getText()).toEqual('')

    # FIXME: Need to discuss this with probablycorey or nathansobo
    xit "does not allow the cursor to be placed on the \n character, unless the line is empty", ->
      editor.setText("012345\n\nabcdef")
      editor.setCursorScreenPosition([0, 5])
      expect(editor.getCursorScreenPosition()).toEqual [0,5]

      editor.setCursorScreenPosition([0, 6])
      expect(editor.getCursorScreenPosition()).toEqual [0,5]

      editor.setCursorScreenPosition([1, 0])
      expect(editor.getCursorScreenPosition()).toEqual [1,0]

    it "clears the operator stack when commands can't be composed", ->
      keydown('d', element: editor[0])
      expect(vimState.opStack.length).toBe 1
      keydown('x', element: editor[0])
      expect(vimState.opStack.length).toBe 0

      keydown('d', element: editor[0])
      expect(vimState.opStack.length).toBe 1
      keydown('\\', element: editor[0])
      expect(vimState.opStack.length).toBe 0

    describe "the escape keybinding", ->
      it "clears the operator stack", ->
        keydown('d', element: editor[0])
        expect(vimState.opStack.length).toBe 1

        keydown('escape', element: editor[0])
        expect(vimState.opStack.length).toBe 0

    describe "the i keybinding", ->
      it "puts the editor into insert mode", ->
        expect(editor).not.toHaveClass 'insert-mode'

        keydown('i', element: editor[0])

        expect(editor).toHaveClass 'insert-mode'
        expect(editor).not.toHaveClass 'command-mode'

    describe "the x keybinding", ->
      it "deletes a character", ->
        editor.setText("012345")
        editor.setCursorScreenPosition([0, 4])

        keydown('x', element: editor[0])
        expect(editor.getText()).toBe '01235'
        expect(editor.getCursorScreenPosition()).toEqual([0, 4])

        keydown('x', element: editor[0])
        expect(editor.getText()).toBe '0123'
        expect(editor.getCursorScreenPosition()).toEqual([0, 3])

        keydown('x', element: editor[0])
        expect(editor.getText()).toBe '012'
        expect(editor.getCursorScreenPosition()).toEqual([0, 2])

      it "deletes nothing when cursor is on empty line", ->
        editor.getBuffer().setText "012345\n\nabcdef"
        editor.setCursorScreenPosition [1, 0]

        keydown('x', element: editor[0])
        expect(editor.getText()).toBe "012345\n\nabcdef"

    describe "the d keybinding", ->
      describe "when followed by a d", ->
        it "deletes the current line", ->
          editor.setText("12345\nabcde\nABCDE")
          editor.setCursorScreenPosition([1,1])

          keydown('d', element: editor[0])
          keydown('d', element: editor[0])
          expect(editor.getText()).toBe "12345\nABCDE"
          expect(editor.getCursorScreenPosition()).toEqual([1,0])

        it "deletes the last line", ->
          editor.setText("12345\nabcde\nABCDE")
          editor.setCursorScreenPosition([2,1])
          keydown('d', element: editor[0])
          keydown('d', element: editor[0])
          expect(editor.getText()).toBe "12345\nabcde"
          expect(editor.getCursorScreenPosition()).toEqual([1,0])

        # FIXME: This functionality wasn't implemented previously.
        xdescribe "when the second d is prefixed by a count", ->
          it "deletes n lines, starting from the current", ->
            editor.setText("12345\nabcde\nABCDE\nQWERT")
            editor.setCursorScreenPosition([1,1])

            keydown('d', element: editor[0])
            keydown('2', element: editor[0])
            keydown('d', element: editor[0])

            expect(editor.getText()).toBe "12345\nQWERT"
            expect(editor.getCursorScreenPosition()).toEqual([1,0])

      describe "when followed by an h", ->
        it "deletes the previous letter on the current line", ->
          editor.setText("abcd\n01234")
          editor.setCursorScreenPosition([1,1])

          keydown('d', element: editor[0])
          keydown('h', element: editor[0])

          expect(editor.getText()).toBe "abcd\n1234"
          expect(editor.getCursorScreenPosition()).toEqual([1,0])

          keydown('d', element: editor[0])
          keydown('h', element: editor[0])

          expect(editor.getText()).toBe "abcd\n1234"
          expect(editor.getCursorScreenPosition()).toEqual([1,0])

      describe "when followed by a w", ->
        it "deletes to the beginning of the next word", ->
          editor.setText("abcd efg")
          editor.setCursorScreenPosition([0,2])

          keydown('d', element: editor[0])
          keydown('w', element: editor[0])

          expect(editor.getText()).toBe "abefg"
          expect(editor.getCursorScreenPosition()).toEqual([0,2])

          editor.setText("one two three four")
          editor.setCursorScreenPosition([0,0])

          keydown('d', element: editor[0])
          keydown('3', element: editor[0])
          keydown('w', element: editor[0])

          expect(editor.getText()).toBe "four"
          expect(editor.getCursorScreenPosition()).toEqual([0,0])

      describe "when followed by a b", ->
        it "deletes to the beginning of the previous word", ->
          editor.setText("abcd efg")
          editor.setCursorScreenPosition([0,2])

          keydown('d', element: editor[0])
          keydown('b', element: editor[0])

          expect(editor.getText()).toBe "cd efg"
          expect(editor.getCursorScreenPosition()).toEqual([0,0])

          editor.setText("one two three four")
          editor.setCursorScreenPosition([0,11])

          keydown('d', element: editor[0])
          keydown('3', element: editor[0])
          keydown('b', element: editor[0])

          expect(editor.getText()).toBe "ee four"
          expect(editor.getCursorScreenPosition()).toEqual([0,0])

    describe "the y keybinding", ->
      beforeEach ->
        editor.getBuffer().setText "012 345\n"
        editor.setCursorScreenPosition [0, 0]

      it "saves the line to the default register", ->
        keydown('y', element: editor[0])
        keydown('y', element: editor[0])

        expect(vimState.getRegister('"')).toBe "012 345\n"

      it "saves the line to the a register", ->
        keydown('"', element: editor[0])
        keydown('a', element: editor[0])
        keydown('y', element: editor[0])
        keydown('y', element: editor[0])

        expect(vimState.getRegister('a')).toBe "012 345\n"

      it "saves the first word to the default register", ->
        keydown('y', element: editor[0])
        keydown('w', element: editor[0])

        expect(vimState.getRegister('"')).toBe "012 "

    describe "the p keybinding", ->
      beforeEach ->
        editor.getBuffer().setText "012\n"
        editor.setCursorScreenPosition [0, 0]
        vimState.setRegister('"', "345\n")
        vimState.setRegister('a', "a\n")

      it "inserts the contents of the default register", ->
        keydown('p', element: editor[0])

        expect(editor.getBuffer().getText()).toBe "345\n012\n"

      it "inserts the contents of the 'a' register", ->
        keydown('"', element: editor[0])
        keydown('a', element: editor[0])
        keydown('p', element: editor[0])

        expect(editor.getBuffer().getText()).toBe "a\n012\n"

    describe "basic motion bindings", ->
      beforeEach ->
        editor.setText("12345\nabcde\nABCDE")
        editor.setCursorScreenPosition([1,1])

      describe "the h keybinding", ->
        it "moves the cursor left, but not to the previous line", ->
          keydown('h', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual([1,0])
          keydown('h', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual([1,0])

        it 'selects the character to the left', ->
          keydown('y', element: editor[0])
          keydown('h', element: editor[0])

          expect(vimState.getRegister('"')).toBe "a"
          expect(editor.getCursorScreenPosition()).toEqual([1,0])

      describe "the j keybinding", ->
        it "moves the cursor down, but not to the end of the last line", ->
          keydown('j', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual([2,1])
          keydown('j', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual([2,1])

      describe "the k keybinding", ->
        it "moves the cursor up, but not to the beginning of the first line", ->
          keydown('k', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual([0,1])
          keydown('k', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual([0,1])

      describe "the l keybinding", ->
        it "moves the cursor right, but not to the next line", ->
          editor.setCursorScreenPosition([1,3])
          keydown('l', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual([1,4])
          keydown('l', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual([1,4])

      describe "the w keybinding", ->
        xit "moves the cursor to the beginning of the next word", ->
          editor.setText("ab cde1+- \n xyz\n\nzip")
          editor.setCursorScreenPosition([0,0])

          keydown('w', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual([0,3])

          keydown('w', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual([0,7])

          keydown('w', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual([1,1])

          keydown('w', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual([2,0])

          # FIXME: The definition of Cursor#getEndOfCurrentWordBufferPosition,
          # means that the end of the word can't be the current cursor
          # position (even though it is when you're cursor is on a new line).
          #
          # Therefore it picks the end of the next word here (which is [3,3])
          # to start looking for the next word, which is also the end of the
          # buffer so the cursor never advances.
          keydown('w', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual([3,0])

          keydown('w', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual([3,2])

        # FIXME: Waiting on github/atom#669 to be resolved.
        xit 'selects to the end of the current word', ->
          editor.setText("ab  cde1+- \n xyz\n\nzip")
          editor.setCursorScreenPosition([0,1])

          keydown('y', element: editor[0])
          keydown('w', element: editor[0])

          expect(vimState.getRegister('"')).toBe "b  "

          editor.setCursorScreenPosition([0,2])

          keydown('y', element: editor[0])
          keydown('w', element: editor[0])

          expect(vimState.getRegister('"')).toBe "  "

      describe "the } keybinding", ->
        beforeEach ->
          editor.setText("abcde\n\nfghij\nhijk\n  xyz  \n\nzip\n\n  \nthe end")
          editor.setCursorScreenPosition([0,0])

        it "moves the cursor to the beginning of the paragraph", ->
          keydown('}', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual [1,0]

          keydown('}', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual [5,0]

          keydown('}', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual [7,0]

          keydown('}', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual [9,6]

        it 'selects to the end of the current word', ->
          keydown('y', element: editor[0])
          keydown('}', element: editor[0])

          expect(vimState.getRegister('"')).toBe "abcde\n"

      describe "the b keybinding", ->
        xit "moves the cursor to the beginning of the previous word", ->
          editor.setText(" ab cde1+- \n xyz\n\nzip }\n last")
          editor.setCursorScreenPosition [4,1]

          keydown('b', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual [3,4]

          keydown('b', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual [3,0]

          keydown('b', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual [2,0]

          keydown('b', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual [1,1]

          keydown('b', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual [0,8]

          keydown('b', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual [0,4]

          keydown('b', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual [0,1]

          # FIXME: The definition of Cursor#getMovePreviousWordBoundaryBufferPosition
          # will always stop on the last word in the buffer. The question is should
          # we change this behavior.
          keydown('b', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual [0,0]

          keydown('b', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual [0,0]

        it 'selects to the beginning of the current word', ->
          editor.setText("ab  cde1+- \n xyz\n\nzip")
          editor.setCursorScreenPosition([0,2])

          keydown('y', element: editor[0])
          keydown('b', element: editor[0])

          expect(vimState.getRegister('"')).toBe "ab"
          expect(editor.getCursorScreenPosition()).toEqual [0,0]

          editor.setCursorScreenPosition([0,4])

          keydown('y', element: editor[0])
          keydown('b', element: editor[0])

          expect(vimState.getRegister('"')).toBe "ab  "
          expect(editor.getCursorScreenPosition()).toEqual [0,0]

    describe "numeric prefix bindings", ->
      it "repeats the following operation N times", ->
        editor.setText("12345")
        editor.setCursorScreenPosition([0,1])

        keydown('3', element: editor[0])
        keydown('x', element: editor[0])

        expect(editor.getText()).toBe '15'

        editor.setText("123456789abc")
        editor.setCursorScreenPosition([0,0])
        keydown('1', element: editor[0])
        keydown('0', element: editor[0])
        keydown('x', element: editor[0])

        expect(editor.getText()).toBe 'bc'

  describe "insert-mode", ->
    beforeEach ->
      editor.trigger keydownEvent('i')

    it "allows the cursor to reach the end of the line", ->
      editor.setText("012345\n\nabcdef")
      editor.setCursorScreenPosition([0, 5])
      expect(editor.getCursorScreenPosition()).toEqual [0,5]

      editor.setCursorScreenPosition([0, 6])
      expect(editor.getCursorScreenPosition()).toEqual [0,6]

    it "puts the editor into command mode when <escape> is pressed", ->
      expect(editor).not.toHaveClass 'command-mode'

      editor.trigger keydownEvent('escape')

      expect(editor).toHaveClass 'command-mode'
      expect(editor).not.toHaveClass 'insert-mode'
