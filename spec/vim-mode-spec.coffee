$ = require 'jquery'

RootView = require 'root-view'
Keymap = require 'keymap'

describe "VimState", ->
  [editor, vimState, originalKeymap] = []

  beforeEach ->
    originalKeymap = window.keymap
    window.keymap = new Keymap

    window.rootView = new RootView
    rootView.open()
    rootView.simulateDomAttachment()
    atom.activatePackage('vim-mode', immediate: true)

    editor = rootView.getActiveView()
    editor.enableKeymap()
    vimState = editor.vimState

  afterEach ->
    window.keymap = originalKeymap

  keydown = (key, {element, ctrl, shift, alt, meta}={}) ->
    dispatchKeyboardEvent = (target, eventArgs...) ->
      e = document.createEvent("KeyboardEvent")
      e.initKeyboardEvent eventArgs...
      target.dispatchEvent e

    dispatchTextEvent = (target, eventArgs...) ->
      e = document.createEvent("TextEvent")
      e.initTextEvent eventArgs...
      target.dispatchEvent e

    key = "U+#{key.charCodeAt(0).toString(16)}" unless key == "escape"
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

    # FIXME: See atom/vim-mode#2
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

    describe "the ctrl-c keybinding", ->
      it "clears the operator stack", ->
        keydown('d', element: editor[0])
        expect(vimState.opStack.length).toBe 1

        keydown('c', ctrl: true, element: editor[0])
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
        expect(vimState.getRegister('"').text).toBe '4'

        keydown('x', element: editor[0])
        expect(editor.getText()).toBe '0123'
        expect(editor.getCursorScreenPosition()).toEqual([0, 3])
        expect(vimState.getRegister('"').text).toBe '5'

        keydown('x', element: editor[0])
        expect(editor.getText()).toBe '012'
        expect(editor.getCursorScreenPosition()).toEqual([0, 2])
        expect(vimState.getRegister('"').text).toBe '3'

      it "deletes nothing when cursor is on empty line", ->
        editor.getBuffer().setText "012345\n\nabcdef"
        editor.setCursorScreenPosition [1, 0]

        keydown('x', element: editor[0])
        expect(editor.getText()).toBe "012345\n\nabcdef"

    describe "the s keybinding", ->
      it "deletes the character to the right and enters insert mode", ->
        editor.setText("012345")
        editor.setCursorScreenPosition([0, 0])

        keydown('s', element: editor[0])
        expect(editor).toHaveClass 'insert-mode'
        expect(editor.getText()).toBe '12345'
        expect(editor.getCursorScreenPosition()).toEqual [0, 0]
        expect(vimState.getRegister('"').text).toBe '0'

      it "deletes count characters to the right and enters insert mode", ->
        editor.setText("012345")
        editor.setCursorScreenPosition([0, 1])

        keydown('3', element: editor[0])
        keydown('s', element: editor[0])
        expect(editor).toHaveClass 'insert-mode'
        expect(editor.getText()).toBe '045'
        expect(editor.getCursorScreenPosition()).toEqual [0, 1]
        # FIXME: See atom/vim-mode#11
        #expect(vimState.getRegister('"').text).toBe '123'

    describe "the S keybinding", ->
      it "deletes the entire line and enters insert mode", ->
        editor.setText("12345\nabcde\nABCDE")
        editor.setCursorScreenPosition([1,3])

        keydown('S', shift: true, element: editor[0])
        expect(editor).toHaveClass 'insert-mode'
        expect(editor.getText()).toBe "12345\n\nABCDE"
        expect(editor.getCursorScreenPosition()).toEqual [1, 0]
        expect(vimState.getRegister('"').text).toBe "abcde\n"
        expect(vimState.getRegister('"').type).toBe "linewise"

    describe "the d keybinding", ->
      describe "when followed by a d", ->
        it "deletes the current line", ->
          editor.setText("12345\nabcde\n\nABCDE")
          editor.setCursorScreenPosition([1,1])

          keydown('d', element: editor[0])
          keydown('d', element: editor[0])
          expect(editor.getText()).toBe "12345\n\nABCDE"
          expect(editor.getCursorScreenPosition()).toEqual([1,0])
          expect(vimState.getRegister('"').text).toBe "abcde\n"

        it "deletes the last line", ->
          editor.setText("12345\nabcde\nABCDE")
          editor.setCursorScreenPosition([2,1])
          keydown('d', element: editor[0])
          keydown('d', element: editor[0])
          expect(editor.getText()).toBe "12345\nabcde"
          expect(editor.getCursorScreenPosition()).toEqual([1,0])

        describe "when the second d is prefixed by a count", ->
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
        it "deletes the next word until the end of the line", ->
          editor.setText("abcd efg\nabc")
          editor.setCursorScreenPosition([0,5])

          keydown('d', element: editor[0])
          keydown('w', element: editor[0])

          expect(editor.getText()).toBe "abcd \nabc"
          expect(editor.getCursorScreenPosition()).toEqual([0,4])

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

    describe "the D keybinding", ->
      beforeEach ->
        editor.getBuffer().setText "012\n"
        editor.setCursorScreenPosition [0, 1]

      it "deletes the contents until the end of the line", ->
        keydown('D', shift: true, element: editor[0])

        expect(editor.getText()).toBe "0\n"

    describe "the c keybinding", ->
      describe "when followed by a c", ->
        it "deletes the current line and enters insert mode", ->
          editor.setText("12345\nabcde\nABCDE")
          editor.setCursorScreenPosition([1,1])

          keydown('c', element: editor[0])
          keydown('c', element: editor[0])
          expect(editor.getText()).toBe "12345\nABCDE"
          expect(editor.getCursorScreenPosition()).toEqual([1,0])
          expect(editor).not.toHaveClass 'command-mode'
          expect(editor).toHaveClass 'insert-mode'

        it "deletes the last line and enters insert mode", ->
          editor.setText("12345\nabcde\nABCDE")
          editor.setCursorScreenPosition([2,1])
          keydown('c', element: editor[0])
          keydown('c', element: editor[0])
          expect(editor.getText()).toBe "12345\nabcde"
          expect(editor.getCursorScreenPosition()).toEqual([1,0])
          expect(editor).not.toHaveClass 'command-mode'
          expect(editor).toHaveClass 'insert-mode'

        describe "when the second c is prefixed by a count", ->
          it "deletes n lines, starting from the current, and enters insert mode", ->
            editor.setText("12345\nabcde\nABCDE\nQWERT")
            editor.setCursorScreenPosition([1,1])

            keydown('c', element: editor[0])
            keydown('2', element: editor[0])
            keydown('c', element: editor[0])

            expect(editor.getText()).toBe "12345\nQWERT"
            expect(editor.getCursorScreenPosition()).toEqual([1,0])
            expect(editor).not.toHaveClass 'command-mode'
            expect(editor).toHaveClass 'insert-mode'

      describe "when followed by an h", ->
        it "deletes the previous letter on the current line and enters insert mode", ->
          editor.setText("abcd\n01234")
          editor.setCursorScreenPosition([1,1])

          keydown('c', element: editor[0])
          keydown('h', element: editor[0])

          expect(editor.getText()).toBe "abcd\n1234"
          expect(editor.getCursorScreenPosition()).toEqual([1,0])
          expect(editor).not.toHaveClass 'command-mode'
          expect(editor).toHaveClass 'insert-mode'

      describe "when followed by a w", ->
        it "deletes to the beginning of the next word and enters insert mode", ->
          editor.setText("abcd efg")
          editor.setCursorScreenPosition([0,2])

          keydown('c', element: editor[0])
          keydown('w', element: editor[0])

          expect(editor.getText()).toBe "ab efg"
          expect(editor.getCursorScreenPosition()).toEqual([0,2])
          expect(editor).not.toHaveClass 'command-mode'
          expect(editor).toHaveClass 'insert-mode'

          keydown('escape', element: editor[0])

          editor.setText("one two three four")
          editor.setCursorScreenPosition([0,0])

          keydown('c', element: editor[0])
          keydown('3', element: editor[0])
          keydown('w', element: editor[0])

          expect(editor.getText()).toBe "four"
          expect(editor.getCursorScreenPosition()).toEqual([0,0])
          expect(editor).not.toHaveClass 'command-mode'
          expect(editor).toHaveClass 'insert-mode'

      describe "when followed by a b", ->
        it "deletes to the beginning of the previous word and enters insert mode", ->
          editor.setText("abcd efg")
          editor.setCursorScreenPosition([0,2])

          keydown('c', element: editor[0])
          keydown('b', element: editor[0])

          expect(editor.getText()).toBe "cd efg"
          expect(editor.getCursorScreenPosition()).toEqual([0,0])
          expect(editor).not.toHaveClass 'command-mode'
          expect(editor).toHaveClass 'insert-mode'

          keydown('escape', element: editor[0])

          editor.setText("one two three four")
          editor.setCursorScreenPosition([0,11])

          keydown('c', element: editor[0])
          keydown('3', element: editor[0])
          keydown('b', element: editor[0])

          expect(editor.getText()).toBe "ee four"
          expect(editor.getCursorScreenPosition()).toEqual([0,0])
          expect(editor).not.toHaveClass 'command-mode'
          expect(editor).toHaveClass 'insert-mode'

    describe "the C keybinding", ->
      beforeEach ->
        editor.getBuffer().setText "012\n"
        editor.setCursorScreenPosition [0, 1]

      it "deletes the contents until the end of the line and enters insert mode", ->
        keydown('C', shift: true, element: editor[0])

        expect(editor.getText()).toBe "0\n"
        expect(editor.getCursorScreenPosition()).toEqual([0,1])
        expect(editor).not.toHaveClass 'command-mode'
        expect(editor).toHaveClass 'insert-mode'

    describe "the y keybinding", ->
      beforeEach ->
        editor.getBuffer().setText "012 345\nabc\n"
        editor.setCursorScreenPosition [0, 4]

      it "saves the line to the default register", ->
        keydown('y', element: editor[0])
        keydown('y', element: editor[0])

        expect(vimState.getRegister('"').text).toBe "012 345\n"
        expect(editor.getCursorScreenPosition()).toEqual([0,4])

      describe "when the second y is prefixed by a count", ->
        it "copies n lines, starting from the current", ->
          keydown('y', element: editor[0])
          keydown('2', element: editor[0])
          keydown('y', element: editor[0])

          expect(vimState.getRegister('"').text).toBe "012 345\nabc\n"

      it "saves the line to the a register", ->
        keydown('"', element: editor[0])
        keydown('a', element: editor[0])
        keydown('y', element: editor[0])
        keydown('y', element: editor[0])

        expect(vimState.getRegister('a').text).toBe "012 345\n"

      it "saves the first word to the default register", ->
        keydown('y', element: editor[0])
        keydown('w', element: editor[0])

        expect(vimState.getRegister('"').text).toBe "345"

    describe "the Y keybinding", ->
      beforeEach ->
        editor.getBuffer().setText "012 345\nabc\n"
        editor.setCursorScreenPosition [0, 4]

      it "saves the line to the default register", ->
        keydown('Y', shift: true, element: editor[0])

        expect(vimState.getRegister('"').text).toBe "012 345\n"
        expect(editor.getCursorScreenPosition()).toEqual([0,4])

      describe "when prefixed by a count", ->
        it "copies n lines, starting from the current", ->
          keydown('2', element: editor[0])
          keydown('Y', shift: true, element: editor[0])

          expect(vimState.getRegister('"').text).toBe "012 345\nabc\n"

      it "saves the line to the a register", ->
        keydown('"', element: editor[0])
        keydown('a', element: editor[0])
        keydown('Y', shift: true, element: editor[0])

        expect(vimState.getRegister('a').text).toBe "012 345\n"

    describe "the p keybinding", ->
      describe 'character', ->
        beforeEach ->
          editor.getBuffer().setText "012\n"
          editor.setCursorScreenPosition [0, 0]
          vimState.setRegister('"', text: "345")
          vimState.setRegister('a', text: "a")

        it "inserts the contents of the default register", ->
          keydown('p', element: editor[0])

          expect(editor.getText()).toBe "034512\n"
          expect(editor.getCursorScreenPosition()).toEqual [0,4]

        it "inserts the contents of the 'a' register", ->
          keydown('"', element: editor[0])
          keydown('a', element: editor[0])
          keydown('p', element: editor[0])

          expect(editor.getText()).toBe "0a12\n"
          expect(editor.getCursorScreenPosition()).toEqual [0,2]

      describe 'linewise', ->
        beforeEach ->
          editor.getBuffer().setText "012\n"
          editor.setCursorScreenPosition [0, 1]
          vimState.setRegister('"', text: " 345\n", type: 'linewise')

        it "inserts the contents of the default register", ->
          keydown('p', element: editor[0])

          expect(editor.getText()).toBe "012\n 345\n"
          expect(editor.getCursorScreenPosition()).toEqual [1,1]

    describe "the P keybinding", ->
      describe 'character', ->
        beforeEach ->
          editor.getBuffer().setText "012\n"
          editor.setCursorScreenPosition [0, 0]
          vimState.setRegister('"', text: "345")
          vimState.setRegister('a', text: "a")

        it "inserts the contents of the default register", ->
          keydown('P', shift: true, element: editor[0])

          expect(editor.getText()).toBe "345012\n"
          expect(editor.getCursorScreenPosition()).toEqual [0,3]

        it "inserts the contents of the 'a' register", ->
          keydown('"', element: editor[0])
          keydown('a', element: editor[0])
          keydown('P', shift: true, element: editor[0])

          expect(editor.getText()).toBe "a012\n"
          expect(editor.getCursorScreenPosition()).toEqual [0,1]

      describe 'linewise', ->
        beforeEach ->
          editor.getBuffer().setText "012\n"
          editor.setCursorScreenPosition [0, 1]
          vimState.setRegister('"', text: " 345\n", type: 'linewise')

        it "inserts the contents of the default register", ->
          keydown('P', shift: true, element: editor[0])

          expect(editor.getText()).toBe " 345\n012\n"
          expect(editor.getCursorScreenPosition()).toEqual [0,1]

    describe "the O keybinding", ->
      beforeEach ->
        spyOn(editor.activeEditSession, 'shouldAutoIndent').andReturn(true)
        spyOn(editor.activeEditSession, 'autoIndentBufferRow').andCallFake (line) ->
          editor.indent()

        editor.getBuffer().setText "  abc\n  012\n"
        editor.setCursorScreenPosition [1, 1]

      it "switches to insert and adds a newline above the current one", ->
        keydown('O', shift: true, element: editor[0])

        expect(editor.getText()).toBe "  abc\n  \n  012\n"
        expect(editor.getCursorScreenPosition()).toEqual [1,2]
        expect(editor).toHaveClass 'insert-mode'

    describe "the o keybinding", ->
      beforeEach ->
        spyOn(editor.activeEditSession, 'shouldAutoIndent').andReturn(true)
        spyOn(editor.activeEditSession, 'autoIndentBufferRow').andCallFake (line) ->
          editor.indent()

        editor.getBuffer().setText "abc\n  012\n"
        editor.setCursorScreenPosition [1, 2]

      it "switches to insert and adds a newline above the current one", ->
        keydown('o', element: editor[0])

        expect(editor.getText()).toBe "abc\n  012\n  \n"
        expect(editor).toHaveClass 'insert-mode'
        expect(editor.getCursorScreenPosition()).toEqual [2,2]

    describe "the a keybinding", ->
      beforeEach ->
        editor.getBuffer().setText "012\n"

      it "switches to insert mode and shifts to the right", ->
        editor.setCursorScreenPosition [0, 0]
        keydown('a', element: editor[0])

        expect(editor.getCursorScreenPosition()).toEqual [0,1]
        expect(editor).toHaveClass 'insert-mode'

      it "doesn't linewrap", ->
        editor.setCursorScreenPosition [0, 3]
        keydown('a', element: editor[0])

        expect(editor.getCursorScreenPosition()).toEqual [0,3]

    describe "the J keybinding", ->
      beforeEach ->
        editor.getBuffer().setText "012\n    456\n"
        editor.setCursorScreenPosition [0, 1]

      it "deletes the contents until the end of the line", ->
        keydown('J', shift: true, element: editor[0])

        expect(editor.getText()).toBe "012 456\n"

    describe "the > keybinding", ->
      describe "when followed by a >", ->
        it "indents the current line", ->
          editor.setText("12345\nabcde\nABCDE")
          editor.setCursorScreenPosition([1,1])

          keydown('>', element: editor[0])
          keydown('>', element: editor[0])
          expect(editor.getText()).toBe "12345\n  abcde\nABCDE"
          expect(editor.getCursorScreenPosition()).toEqual([1,2])

        it "indents multiple lines at once", ->
          editor.setText("12345\nabcde\nABCDE")
          editor.setCursorScreenPosition([0,0])

          keydown('3', element: editor[0])
          keydown('>', element: editor[0])
          keydown('>', element: editor[0])
          expect(editor.getText()).toBe "  12345\n  abcde\n  ABCDE"
          expect(editor.getCursorScreenPosition()).toEqual([0,2])

          keydown('u', element: editor[0])
          expect(editor.getText()).toBe "12345\nabcde\nABCDE"


    describe "the < keybinding", ->
      describe "when followed by a <", ->
        it "indents the current line", ->
          expect(editor.setText("12345\n  abcde\nABCDE"))
          editor.setCursorScreenPosition([1,2])

          keydown('<', element: editor[0])
          keydown('<', element: editor[0])
          expect(editor.getText()).toBe "12345\nabcde\nABCDE"
          expect(editor.getCursorScreenPosition()).toEqual([1,0])

        it "indents multiple lines at once", ->
          editor.setText("  12345\n  abcde\n  ABCDE")
          editor.setCursorScreenPosition([0,0])

          keydown('3', element: editor[0])
          keydown('<', element: editor[0])
          keydown('<', element: editor[0])
          expect(editor.getText()).toBe "12345\nabcde\nABCDE"
          expect(editor.getCursorScreenPosition()).toEqual([0,0])

          keydown('u', element: editor[0])
          expect(editor.getText()).toBe "  12345\n  abcde\n  ABCDE"

    describe "motion bindings", ->
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

          expect(vimState.getRegister('"').text).toBe "a"
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
          #
          # See atom/vim-mode#3
          keydown('w', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual([3,0])

          keydown('w', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual([3,2])

        it 'selects to the end of the current word', ->
          editor.setText("ab  cde1+- \n xyz\n\nzip")
          editor.setCursorScreenPosition([0,1])

          keydown('y', element: editor[0])
          keydown('w', element: editor[0])

          expect(vimState.getRegister('"').text).toBe "b  "

          editor.setCursorScreenPosition([0,2])

          keydown('y', element: editor[0])
          keydown('w', element: editor[0])

          expect(vimState.getRegister('"').text).toBe "  "

      describe "the e keybinding", ->
        it "moves the cursor to the end of the current word", ->
          editor.setText("ab cde1+- \n xyz\n\nzip")
          editor.setCursorScreenPosition([0, 0])

          keydown('e', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual [0, 1]

          keydown('e', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual [0, 6]

          keydown('e', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual [0, 8]

          keydown('e', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual [1, 3]

          # INCOMPATIBILITY: vim doesn't stop at [2, 0] it advances immediately
          # to [3, 2]
          keydown('e', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual [2, 0]

          keydown('e', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual [3, 2]

        it 'selects to the end of the current word', ->
          editor.setText("ab  cde1+- \n xyz\n\nzip")
          editor.setCursorScreenPosition([0, 0])

          keydown('y', element: editor[0])
          keydown('e', element: editor[0])

          expect(vimState.getRegister('"').text).toBe "ab"

          editor.setCursorScreenPosition([0,2])

          keydown('y', element: editor[0])
          keydown('e', element: editor[0])

          expect(vimState.getRegister('"').text).toBe "  cde1"

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

          expect(vimState.getRegister('"').text).toBe "abcde\n"

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
          #
          # See atom/vim-mode#3
          keydown('b', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual [0,0]

          keydown('b', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual [0,0]

        it 'selects to the beginning of the current word', ->
          editor.setText("ab  cde1+- \n xyz\n\nzip")
          editor.setCursorScreenPosition([0,2])

          keydown('y', element: editor[0])
          keydown('b', element: editor[0])

          expect(vimState.getRegister('"').text).toBe "ab"
          expect(editor.getCursorScreenPosition()).toEqual [0,0]

          editor.setCursorScreenPosition([0,4])

          keydown('y', element: editor[0])
          keydown('b', element: editor[0])

          expect(vimState.getRegister('"').text).toBe "ab  "
          expect(editor.getCursorScreenPosition()).toEqual [0,0]

      describe "the ^ keybinding", ->
        beforeEach ->
          editor.setText("  abcde")
          editor.setCursorScreenPosition([0,4])

        it 'moves the cursor to the beginning of the line', ->
          keydown('^', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual [0,2]

        it 'selects to the beginning of the lines', ->
          keydown('d', element: editor[0])
          keydown('^', element: editor[0])

          expect(editor.getText()).toBe '  cde'
          expect(editor.getCursorScreenPosition()).toEqual [0,2]

      describe "the $ keybinding", ->
        beforeEach ->
          editor.setText("  abcde\n")
          editor.setCursorScreenPosition([0,4])

        # FIXME: See atom/vim-mode#2
        xit 'moves the cursor to the end of the line', ->
          keydown('$', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual [0,6]

        it 'selects to the beginning of the lines', ->
          keydown('d', element: editor[0])
          keydown('$', element: editor[0])

          expect(editor.getText()).toBe "  ab\n"
          # FIXME: See atom/vim-mode#2
          #expect(editor.getCursorScreenPosition()).toEqual [0,3]

      # FIXME: this doesn't work as we can't determine if this is a motion
      # or part of a repeat prefix.
      xdescribe "the 0 keybinding", ->
        beforeEach ->
          editor.setText("  a\n")
          editor.setCursorScreenPosition([0,2])

        it 'moves the cursor to the beginning of the line', ->
          keydown('0', element: editor[0])
          expect(editor.getCursorScreenPosition()).toEqual [0,0]

      describe "the gg keybinding", ->
        beforeEach ->
          editor.setText(" 1abc\n2\n3\n")
          editor.setCursorScreenPosition([0,2])

        it 'moves the cursor to the beginning of the first line', ->
          keydown('g', element: editor[0])
          keydown('g', element: editor[0])

          expect(editor.getCursorScreenPosition()).toEqual [0, 1]

      describe "the G keybinding", ->
        beforeEach ->
          editor.setText("1\n    2\n 3abc\n ")
          editor.setCursorScreenPosition([0,2])

        it 'moves the cursor to the last line after whitespace', ->
          keydown('G', shift: true, element: editor[0])

          expect(editor.getCursorScreenPosition()).toEqual [3, 1]

        it 'moves the cursor to a specified line', ->
          keydown('2', element: editor[0])
          keydown('G', shift: true, element: editor[0])

          expect(editor.getCursorScreenPosition()).toEqual [1, 4]

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

      it "repeats the following motion N times", ->
        editor.setText("one two three")
        editor.setCursorScreenPosition([0,0])

        keydown('d', element: editor[0])
        keydown('2', element: editor[0])
        keydown('w', element: editor[0])

        expect(editor.getText()).toBe 'three'

  describe "undo", ->
    describe "delete operator", ->
      it "handles repeats", ->
        editor.setText("12345\nabcde\nABCDE\nQWERT")
        editor.setCursorScreenPosition([1,1])

        keydown('d', element: editor[0])
        keydown('2', element: editor[0])
        keydown('d', element: editor[0])

        keydown('u', element: editor[0])

        expect(editor.getText()).toBe "12345\nabcde\nABCDE\nQWERT"

    describe "put operator", ->
      it "handles repeats", ->
        editor.setText("12345\nabcde\nABCDE\nQWERT")
        editor.setCursorScreenPosition([1,1])
        vimState.setRegister('"', text: "123")

        keydown('2', element: editor[0])
        keydown('p', element: editor[0])

        keydown('u', element: editor[0])

        expect(editor.getText()).toBe "12345\nabcde\nABCDE\nQWERT"

    describe "join operator", ->
      it "handles repeats", ->
        editor.setText("12345\nabcde\nABCDE\nQWERT")
        editor.setCursorScreenPosition([1,1])

        keydown('2', element: editor[0])
        keydown('J', shift: true, element: editor[0])

        keydown('u', element: editor[0])

        expect(editor.getText()).toBe "12345\nabcde\nABCDE\nQWERT"

  describe "insert-mode", ->
    beforeEach ->
      keydown('i', element: editor[0])

    it "allows the cursor to reach the end of the line", ->
      editor.setText("012345\n\nabcdef")
      editor.setCursorScreenPosition([0, 5])
      expect(editor.getCursorScreenPosition()).toEqual [0,5]

      editor.setCursorScreenPosition([0, 6])
      expect(editor.getCursorScreenPosition()).toEqual [0,6]

    it "puts the editor into command mode when <escape> is pressed", ->
      expect(editor).not.toHaveClass 'command-mode'

      keydown('escape', element: editor[0])

      expect(editor).toHaveClass 'command-mode'
      expect(editor).not.toHaveClass 'insert-mode'

    it "puts the editor into command mode when <ctrl-c> is pressed", ->
      expect(editor).not.toHaveClass 'command-mode'

      keydown('c', ctrl: true, element: editor[0])

      expect(editor).toHaveClass 'command-mode'
      expect(editor).not.toHaveClass 'insert-mode'
