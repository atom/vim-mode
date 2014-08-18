helpers = require './spec-helper'

describe "Operators", ->
  [editor, editorView, vimState] = []

  beforeEach ->
    vimMode = atom.packages.loadPackage('vim-mode')
    vimMode.activateResources()

    helpers.cacheEditor editorView, (view) ->
      editorView = view
      editor = editorView.editor

      vimState = editorView.vimState
      vimState.activateCommandMode()
      vimState.resetCommandMode()

  keydown = (key, options={}) ->
    options.element ?= editorView[0]
    helpers.keydown(key, options)

  commandModeInputKeydown = (key, opts = {}) ->
    opts.element = editor.commandModeInputView.editor.find('input').get(0)
    opts.raw = true
    keydown(key, opts)

  describe "cancel operation is robust", ->
    it "can call cancel operation, even if no operator pending", ->
      # cancel operation pushes an empty input operation
      # doing this without a pending operation throws an exception
      expect(-> vimState.pushOperations(new Input(''))).toThrow()

      # make sure commandModeInputView is created
      keydown('/')
      expect(vimState.isOperatorPending()).toBe true
      editor.commandModeInputView.viewModel.cancel()

      # now again cancel op, although there is none pending
      expect(vimState.isOperatorPending()).toBe false

      # which should not raise an exception
      expect(-> editor.commandModeInputView.viewModel.cancel()).not.toThrow()


  describe "the x keybinding", ->
    describe "on a line with content", ->
      beforeEach ->
        editor.setText("012345")
        editor.setCursorScreenPosition([0, 4])

      it "deletes a character", ->
        keydown('x')
        expect(editor.getText()).toBe '01235'
        expect(editor.getCursorScreenPosition()).toEqual [0, 4]
        expect(vimState.getRegister('"').text).toBe '4'

        keydown('x')
        expect(editor.getText()).toBe '0123'
        expect(editor.getCursorScreenPosition()).toEqual [0, 3]
        expect(vimState.getRegister('"').text).toBe '5'

        keydown('x')
        expect(editor.getText()).toBe '012'
        expect(editor.getCursorScreenPosition()).toEqual [0, 2]
        expect(vimState.getRegister('"').text).toBe '3'

    describe "on an empty line", ->
      beforeEach ->
        editor.setText("012345\n\nabcdef")
        editor.setCursorScreenPosition([1, 0])
        keydown('x')

      it "deletes nothing when cursor is on empty line", ->
        expect(editor.getText()).toBe "012345\n\nabcdef"

  describe "the X keybinding", ->
    describe "on a line with content", ->
      beforeEach ->
        editor.setText("012345")
        editor.setCursorScreenPosition([0, 2])

      it "deletes a character", ->
        keydown('X', shift: true)
        expect(editor.getText()).toBe '02345'
        expect(editor.getCursorScreenPosition()).toEqual [0, 1]
        expect(vimState.getRegister('"').text).toBe '1'

        keydown('X', shift: true)
        expect(editor.getText()).toBe '2345'
        expect(editor.getCursorScreenPosition()).toEqual [0, 0]
        expect(vimState.getRegister('"').text).toBe '0'

        keydown('X', shift: true)
        expect(editor.getText()).toBe '2345'
        expect(editor.getCursorScreenPosition()).toEqual [0, 0]
        expect(vimState.getRegister('"').text).toBe '0'

    describe "on an empty line", ->
      beforeEach ->
        editor.setText("012345\n\nabcdef")
        editor.setCursorScreenPosition([1, 0])
        keydown('X', shift: true)

      it "deletes nothing when cursor is on empty line", ->
        expect(editor.getText()).toBe "012345\n\nabcdef"

  describe "the s keybinding", ->
    beforeEach ->
      editor.setText('012345')
      editor.setCursorScreenPosition([0, 1])

    it "deletes the character to the right and enters insert mode", ->
      keydown('s')
      expect(editorView).toHaveClass 'insert-mode'
      expect(editor.getText()).toBe '02345'
      expect(editor.getCursorScreenPosition()).toEqual [0, 1]
      expect(vimState.getRegister('"').text).toBe '1'

    it "is repeatable", ->
      editor.setCursorScreenPosition([0, 0])
      keydown('3')
      keydown('s')
      editor.insertText("ab")
      keydown('escape')
      expect(editor.getText()).toBe 'ab345'
      editor.setCursorScreenPosition([0, 2])
      keydown('.')
      expect(editor.getText()).toBe 'abab'

    it "is undoable", ->
      editor.setCursorScreenPosition([0, 0])
      keydown('3')
      keydown('s')
      editor.insertText("ab")
      keydown('escape')
      expect(editor.getText()).toBe 'ab345'
      keydown('u')
      expect(editor.getText()).toBe '012345'

    describe "in visual mode", ->
      beforeEach ->
        keydown('v')
        editor.selectRight()
        editor.selectRight()
        keydown('s')

      it "deletes the selected characters and enters insert mode", ->
        expect(editorView).toHaveClass 'insert-mode'
        expect(editor.getText()).toBe '0345'
        expect(editor.getCursorScreenPosition()).toEqual [0, 1]
        expect(vimState.getRegister('"').text).toBe '12'

  describe "the S keybinding", ->
    beforeEach ->
      editor.setText("12345\nabcde\nABCDE")
      editor.setCursorScreenPosition([1, 3])

    it "deletes the entire line and enters insert mode", ->
      keydown('S', shift: true)
      expect(editorView).toHaveClass 'insert-mode'
      expect(editor.getText()).toBe "12345\n\nABCDE"
      expect(editor.getCursorScreenPosition()).toEqual [1, 0]
      expect(vimState.getRegister('"').text).toBe "abcde\n"
      expect(vimState.getRegister('"').type).toBe 'linewise'

    it "is repeatable", ->
      keydown('S', shift: true)
      editor.insertText("abc")
      keydown 'escape'
      expect(editor.getText()).toBe "12345\nabc\nABCDE"
      editor.setCursorScreenPosition([2, 3])
      keydown '.'
      expect(editor.getText()).toBe "12345\nabc\nabc\n"

    it "is undoable", ->
      keydown('S', shift: true)
      editor.insertText("abc")
      keydown 'escape'
      expect(editor.getText()).toBe "12345\nabc\nABCDE"
      keydown 'u'
      expect(editor.getText()).toBe "12345\nabcde\nABCDE"

    # Can't be tested without setting grammar of test buffer
    xit "respects indentation", ->

  describe "the d keybinding", ->
    it "enters operator-pending mode", ->
      keydown('d')
      expect(editorView).toHaveClass('operator-pending-mode')
      expect(editorView).not.toHaveClass('command-mode')

    describe "when followed by a d", ->
      it "deletes the current line and exits operator-pending mode", ->
        editor.setText("12345\nabcde\n\nABCDE")
        editor.setCursorScreenPosition([1, 1])

        keydown('d')
        keydown('d')

        expect(editor.getText()).toBe "12345\n\nABCDE"
        expect(editor.getCursorScreenPosition()).toEqual [1, 0]
        expect(vimState.getRegister('"').text).toBe "abcde\n"
        expect(editorView).not.toHaveClass('operator-pending-mode')
        expect(editorView).toHaveClass('command-mode')

      it "deletes the last line", ->
        editor.setText("12345\nabcde\nABCDE")
        editor.setCursorScreenPosition([2, 1])

        keydown('d')
        keydown('d')

        expect(editor.getText()).toBe "12345\nabcde"
        expect(editor.getCursorScreenPosition()).toEqual [1, 0]

    describe "undo behavior", ->
      beforeEach ->
        editor.setText("12345\nabcde\nABCDE\nQWERT")
        editor.setCursorScreenPosition([1,1])

        keydown('d')
        keydown('2')
        keydown('d')

        keydown('u')

      it "undoes both lines", ->
        expect(editor.getText()).toBe "12345\nabcde\nABCDE\nQWERT"

    describe "when followed by a w", ->
      it "deletes the next word until the end of the line and exits operator-pending mode", ->
        editor.setText("abcd efg\nabc")
        editor.setCursorScreenPosition([0, 5])

        keydown('d')
        keydown('w')

        expect(editor.getText()).toBe "abcd \nabc"
        expect(editor.getCursorScreenPosition()).toEqual [0, 4]
        expect(editorView).not.toHaveClass('operator-pending-mode')
        expect(editorView).toHaveClass('command-mode')

      it "deletes to the beginning of the next word", ->
        editor.setText('abcd efg')
        editor.setCursorScreenPosition([0, 2])

        keydown('d')
        keydown('w')

        expect(editor.getText()).toBe 'abefg'
        expect(editor.getCursorScreenPosition()).toEqual [0, 2]

        editor.setText('one two three four')
        editor.setCursorScreenPosition([0, 0])

        keydown('d')
        keydown('3')
        keydown('w')

        expect(editor.getText()).toBe 'four'
        expect(editor.getCursorScreenPosition()).toEqual [0, 0]

    describe "when followed by an iw", ->
      it "deletes the containing word", ->
        editor.setText("12345 abcde ABCDE")
        editor.setCursorScreenPosition([0, 9])

        keydown('d')
        expect(editorView).toHaveClass('operator-pending-mode')
        keydown('i')
        keydown('w')

        expect(editor.getText()).toBe "12345  ABCDE"
        expect(editor.getCursorScreenPosition()).toEqual [0, 6]
        expect(vimState.getRegister('"').text).toBe "abcde"
        expect(editorView).not.toHaveClass('operator-pending-mode')
        expect(editorView).toHaveClass('command-mode')

    describe "when followed by an j", ->
      beforeEach ->
        originalText = "12345\nabcde\nABCDE"
        editor.setText(originalText)

        describe "on the beginning of the file", ->
          editor.setCursorScreenPosition([0, 0])
          it "deletes the next two lines", ->
            keydown('d')
            keydown('j')
            expect(editor.getText()).toBe("ABCDE")

        describe "on the end of the file", ->
          editor.setCursorScreenPosition([4,2])
          it "deletes nothing", ->
            keydown('d')
            keydown('j')
            expect(editor.getText()).toBe(originalText)

        describe "on the middle of second line", ->
          editor.setCursorScreenPosition([2,1])
          it "deletes the last two lines", ->
            keydown('d')
            keydown('j')
            expect(editor.getText()).toBe("12345")

    describe "when followed by an k", ->
      beforeEach ->
        originalText = "12345\nabcde\nABCDE"
        editor.setText(originalText)

        describe "on the end of the file", ->
          editor.setCursorScreenPosition([4, 2])
          it "deletes the bottom two lines", ->
            keydown('d')
            keydown('k')
            expect(editor.getText()).toBe("ABCDE")

        describe "on the beginning of the file", ->
          editor.setCursorScreenPosition([0,0])
          it "deletes nothing", ->
            keydown('d')
            keydown('k')
            expect(editor.getText()).toBe(originalText)

        describe "when on the middle of second line", ->
          editor.setCursorScreenPosition([2,1])
          it "deletes the first two lines", ->
            keydown('d')
            keydown('k')
            expect(editor.getText()).toBe("12345")


  describe "the D keybinding", ->
    beforeEach ->
      editor.getBuffer().setText("012\n")
      editor.setCursorScreenPosition([0, 1])
      keydown('D', shift: true)

    it "deletes the contents until the end of the line", ->
      expect(editor.getText()).toBe "0\n"

  describe "the c keybinding", ->
    beforeEach ->
      editor.setText("12345\nabcde\nABCDE")

    describe "when followed by a c", ->
      it "deletes the current line and enters insert mode", ->
        editor.setCursorScreenPosition([1, 1])

        keydown('c')
        keydown('c')

        expect(editor.getText()).toBe "12345\n\nABCDE"
        expect(editor.getCursorScreenPosition()).toEqual [1, 0]
        expect(editorView).not.toHaveClass 'command-mode'
        expect(editorView).toHaveClass 'insert-mode'

      describe "when the cursor is on the last line", ->
        it "deletes the line's content and enters insert mode on the last line", ->
          editor.setCursorScreenPosition([2, 1])

          keydown('c')
          keydown('c')

          expect(editor.getText()).toBe "12345\nabcde\n"
          expect(editor.getCursorScreenPosition()).toEqual [2, 0]
          expect(editorView).not.toHaveClass 'command-mode'
          expect(editorView).toHaveClass 'insert-mode'

      describe "when the cursor is on the only line", ->
        it "deletes the line's content and enters insert mode", ->
          editor.setText("12345")
          editor.setCursorScreenPosition([0, 2])

          keydown('c')
          keydown('c')

          expect(editor.getText()).toBe ""
          expect(editor.getCursorScreenPosition()).toEqual [0, 0]
          expect(editorView).not.toHaveClass 'command-mode'
          expect(editorView).toHaveClass 'insert-mode'

    describe "when followed by i w", ->
      it "undo's and redo's completely", ->
        editor.setCursorScreenPosition([1, 1])

        keydown('c')
        keydown('i')
        keydown('w')
        expect(editor.getText()).toBe "12345\n\nABCDE"
        expect(editor.getCursorScreenPosition()).toEqual [1, 0]
        expect(editorView).toHaveClass 'insert-mode'

        # Just cannot get "typing" to work correctly in test.
        editor.setText("12345\nfg\nABCDE")
        keydown('escape')
        expect(editorView).toHaveClass 'command-mode'
        expect(editor.getText()).toBe "12345\nfg\nABCDE"

        keydown('u')
        expect(editor.getText()).toBe "12345\nabcde\nABCDE"
        keydown('r', ctrl: true)
        expect(editor.getText()).toBe "12345\nfg\nABCDE"

  describe "the C keybinding", ->
    beforeEach ->
      editor.getBuffer().setText("012\n")
      editor.setCursorScreenPosition([0, 1])
      keydown('C', shift: true)

    it "deletes the contents until the end of the line and enters insert mode", ->
      expect(editor.getText()).toBe "0\n"
      expect(editor.getCursorScreenPosition()).toEqual [0, 1]
      expect(editorView).not.toHaveClass 'command-mode'
      expect(editorView).toHaveClass 'insert-mode'

  describe "the y keybinding", ->
    beforeEach ->
      editor.getBuffer().setText("012 345\nabc\n")
      editor.setCursorScreenPosition([0, 4])

    describe "when selected lines in visual linewise mode", ->
      beforeEach ->
        keydown('V', shift: true)
        keydown('j')
        keydown('y')

      it "is in linewise motion", ->
        expect(vimState.getRegister('"').type).toEqual "linewise"

      it "saves the lines to the default register", ->
        expect(vimState.getRegister('"').text).toBe "012 345\nabc\n"

    describe "when followed by a second y ", ->
      beforeEach ->
        keydown('y')
        keydown('y')

      it "saves the line to the default register", ->
        expect(vimState.getRegister('"').text).toBe "012 345\n"

      it "leaves the cursor at the starting position", ->
        expect(editor.getCursorScreenPosition()).toEqual [0, 4]

    describe "when followed with a repeated y", ->
      beforeEach ->
        keydown('y')
        keydown('2')
        keydown('y')

      it "copies n lines, starting from the current", ->
        expect(vimState.getRegister('"').text).toBe "012 345\nabc\n"

      it "leaves the cursor at the starting position", ->
        expect(editor.getCursorScreenPosition()).toEqual [0, 4]

    describe "with a register", ->
      beforeEach ->
        keydown('"')
        keydown('a')
        keydown('y')
        keydown('y')

      it "saves the line to the a register", ->
        expect(vimState.getRegister('a').text).toBe "012 345\n"

    describe "with a motion", ->
      beforeEach ->
        keydown('y')
        keydown('w')

      it "saves the first word to the default register", ->
        expect(vimState.getRegister('"').text).toBe '345'

      it "leaves the cursor at the starting position", ->
        expect(editor.getCursorScreenPosition()).toEqual [0, 4]

    describe "with a left motion", ->
      beforeEach ->
        keydown('y')
        keydown('h')

        it "saves the left letter to the default register", ->
          expect(vimState.getRegister('"').text).toBe " "

        it "moves the cursor position to the left", ->
          expect(editor.getCursorScreenPosition()).toEqual [0, 3]

    describe "with a down motion", ->
      beforeEach ->
        keydown 'y'
        keydown 'j'

      it "saves both full lines to the default register", ->
        expect(vimState.getRegister('"').text).toBe "012 345\nabc\n"

      it "leaves the cursor at the starting position", ->
        expect(editor.getCursorScreenPosition()).toEqual [0, 4]

  describe "the yy keybinding", ->
    describe "on a single line file", ->
      beforeEach ->
        editor.getBuffer().setText "exclamation!\n"
        editor.setCursorScreenPosition [0, 0]

      it "copies the entire line and pastes it correctly", ->
        keydown('y')
        keydown('y')
        keydown('p')

        expect(vimState.getRegister('"').text).toBe "exclamation!\n"
        expect(editor.getText()).toBe "exclamation!\nexclamation!\n"

    describe "on a single line file with no newline", ->
      beforeEach ->
        editor.getBuffer().setText "no newline!"
        editor.setCursorScreenPosition [0, 0]

      it "copies the entire line and pastes it correctly", ->
        keydown('y')
        keydown('y')
        keydown('p')

        expect(vimState.getRegister('"').text).toBe "no newline!\n"
        expect(editor.getText()).toBe "no newline!\nno newline!"

      it "copies the entire line and pastes it respecting count and new lines", ->
        keydown('y')
        keydown('y')
        keydown('2')
        keydown('p')

        expect(vimState.getRegister('"').text).toBe "no newline!\n"
        expect(editor.getText()).toBe "no newline!\nno newline!\nno newline!"

  describe "the Y keybinding", ->
    beforeEach ->
      editor.getBuffer().setText "012 345\nabc\n"
      editor.setCursorScreenPosition [0, 4]

    it "saves the line to the default register", ->
      keydown('Y', shift: true)

      expect(vimState.getRegister('"').text).toBe "012 345\n"
      expect(editor.getCursorScreenPosition()).toEqual [0, 4]

  describe "the p keybinding", ->
    describe "with character contents", ->
      beforeEach ->
        editor.getBuffer().setText "012\n"
        editor.setCursorScreenPosition [0, 0]
        vimState.setRegister('"', text: '345')
        vimState.setRegister('a', text: 'a')

      describe "from the default register", ->
        beforeEach -> keydown('p')

        it "inserts the contents", ->
          expect(editor.getText()).toBe "034512\n"
          expect(editor.getCursorScreenPosition()).toEqual [0, 3]

      describe "from a specified register", ->
        beforeEach ->
          keydown('"')
          keydown('a')
          keydown('p')

        it "inserts the contents of the 'a' register", ->
          expect(editor.getText()).toBe "0a12\n"
          expect(editor.getCursorScreenPosition()).toEqual [0, 1]

      describe "at the end of a line", ->
        it "inserts before the current line's newline", ->
          editor.setText("abcde\none two three")
          editor.setCursorScreenPosition([1, 4])

          keydown 'd'
          keydown '$'
          keydown 'k'
          keydown '$'
          keydown 'p'

          expect(editor.getText()).toBe "abcdetwo three\none "

      describe "with a selection", ->
        beforeEach ->
          editor.selectRight()
          keydown('p')

        it "replaces the current selection", ->
          expect(editor.getText()).toBe "34512\n"
          expect(editor.getCursorScreenPosition()).toEqual [0, 2]

    describe "with linewise contents", ->
      describe "on a single line", ->
        beforeEach ->
          editor.getBuffer().setText("012")
          editor.setCursorScreenPosition([0, 1])
          vimState.setRegister('"', text: " 345\n", type: 'linewise')

        it "inserts the contents of the default register", ->
          keydown('p')

          expect(editor.getText()).toBe "012\n 345"
          expect(editor.getCursorScreenPosition()).toEqual [1, 1]

        it "replaces the current selection", ->
          editor.selectRight()
          keydown('p')

          expect(editor.getText()).toBe "0 345\n2"
          expect(editor.getCursorScreenPosition()).toEqual [1, 0]

      describe "on multiple lines", ->
        beforeEach ->
          editor.getBuffer().setText("012\n 345")
          vimState.setRegister('"', text: " 456\n", type: 'linewise')

        it "inserts the contents of the default register at middle line", ->
          editor.setCursorScreenPosition([0, 1])
          keydown('p')

          expect(editor.getText()).toBe "012\n 456\n 345"
          expect(editor.getCursorScreenPosition()).toEqual [1, 1]

        it "inserts the contents of the default register at end of line", ->
          editor.setCursorScreenPosition([1, 1])
          keydown('p')

          expect(editor.getText()).toBe "012\n 345\n 456"
          expect(editor.getCursorScreenPosition()).toEqual [2, 1]

    describe "with multiple linewise contents", ->
      beforeEach ->
        editor.getBuffer().setText("012\nabc")
        editor.setCursorScreenPosition([1, 0])
        vimState.setRegister('"', text: " 345\n 678\n", type: 'linewise')
        keydown('p')

      it "inserts the contents of the default register", ->
        expect(editor.getText()).toBe "012\nabc\n 345\n 678"
        expect(editor.getCursorScreenPosition()).toEqual [2, 1]

    describe "pasting twice", ->
      beforeEach ->
        editor.setText("12345\nabcde\nABCDE\nQWERT")
        editor.setCursorScreenPosition([1, 1])
        vimState.setRegister('"', text: '123')
        keydown('2')
        keydown('p')

      it "inserts the same line twice", ->
        expect(editor.getText()).toBe "12345\nab123123cde\nABCDE\nQWERT"

      describe "when undone", ->
        beforeEach ->
          keydown('u')

        it "removes both lines", ->
          expect(editor.getText()).toBe "12345\nabcde\nABCDE\nQWERT"

  describe "the P keybinding", ->
    describe "with character contents", ->
      beforeEach ->
        editor.getBuffer().setText("012\n")
        editor.setCursorScreenPosition([0, 0])
        vimState.setRegister('"', text: '345')
        vimState.setRegister('a', text: 'a')
        keydown('P', shift: true)

      it "inserts the contents of the default register above", ->
        expect(editor.getText()).toBe "345012\n"
        expect(editor.getCursorScreenPosition()).toEqual [0, 2]

  describe "the O keybinding", ->
    beforeEach ->
      spyOn(editor, 'shouldAutoIndent').andReturn(true)
      spyOn(editor, 'autoIndentBufferRow').andCallFake (line) ->
        editor.indent()

      editor.getBuffer().setText("  abc\n  012\n")
      editor.setCursorScreenPosition([1, 1])

    it "switches to insert and adds a newline above the current one", ->
      keydown('O', shift: true)
      expect(editor.getText()).toBe "  abc\n  \n  012\n"
      expect(editor.getCursorScreenPosition()).toEqual [1, 2]
      expect(editorView).toHaveClass 'insert-mode'

    it "is repeatable", ->
      editor.getBuffer().setText("  abc\n  012\n    4spaces\n")
      editor.setCursorScreenPosition([1, 1])
      keydown('O', shift: true)
      editor.insertText "def"
      keydown 'escape'
      expect(editor.getText()).toBe "  abc\n  def\n  012\n    4spaces\n"
      editor.setCursorScreenPosition([1, 1])
      keydown '.'
      expect(editor.getText()).toBe "  abc\n  def\n  def\n  012\n    4spaces\n"
      editor.setCursorScreenPosition([4, 1])
      keydown '.'
      expect(editor.getText()).toBe "  abc\n  def\n  def\n  012\n    def\n    4spaces\n"

    it "is undoable", ->
      keydown('O', shift: true)
      editor.insertText "def"
      keydown 'escape'
      expect(editor.getText()).toBe "  abc\n  def\n  012\n"
      keydown 'u'
      expect(editor.getText()).toBe "  abc\n  012\n"

  describe "the o keybinding", ->
    beforeEach ->
      spyOn(editor, 'shouldAutoIndent').andReturn(true)
      spyOn(editor, 'autoIndentBufferRow').andCallFake (line) ->
        editor.indent()

      editor.getBuffer().setText("abc\n  012\n")
      editor.setCursorScreenPosition([1, 2])

    it "switches to insert and adds a newline above the current one", ->
      keydown('o')
      expect(editor.getText()).toBe "abc\n  012\n  \n"
      expect(editorView).toHaveClass 'insert-mode'
      expect(editor.getCursorScreenPosition()).toEqual [2, 2]

    # This works in practice, but the editor doesn't respect the indentation
    # rules without a syntax grammar. Need to set the editor's grammar
    # to fix it.
    xit "is repeatable", ->
      editor.getBuffer().setText("  abc\n  012\n    4spaces\n")
      editor.setCursorScreenPosition([1, 1])
      keydown('o')
      editor.insertText "def"
      keydown 'escape'
      expect(editor.getText()).toBe "  abc\n  012\n  def\n    4spaces\n"
      keydown '.'
      expect(editor.getText()).toBe "  abc\n  012\n  def\n  def\n    4spaces\n"
      editor.setCursorScreenPosition([4, 1])
      keydown '.'
      expect(editor.getText()).toBe "  abc\n  def\n  def\n  012\n    4spaces\n    def\n"

    it "is undoable", ->
      keydown('o')
      editor.insertText "def"
      keydown 'escape'
      expect(editor.getText()).toBe "abc\n  012\n  def\n"
      keydown 'u'
      expect(editor.getText()).toBe "abc\n  012\n"


  describe "the a keybinding", ->
    beforeEach ->
      editor.getBuffer().setText("012\n")

    describe "at the beginning of the line", ->
      beforeEach ->
        editor.setCursorScreenPosition([0, 0])
        keydown('a')

      it "switches to insert mode and shifts to the right", ->
        expect(editor.getCursorScreenPosition()).toEqual [0, 1]
        expect(editorView).toHaveClass 'insert-mode'

    describe "at the end of the line", ->
      beforeEach ->
        editor.setCursorScreenPosition([0, 3])
        keydown('a')

      it "doesn't linewrap", ->
        expect(editor.getCursorScreenPosition()).toEqual [0, 3]

  describe "the A keybinding", ->
    beforeEach ->
      editor.getBuffer().setText("11\n22\n")

    describe "at the beginning of a line", ->
      it "switches to insert mode at the end of the line", ->
        editor.setCursorScreenPosition([0,0])
        keydown('A', shift: true)

        expect(editorView).toHaveClass 'insert-mode'
        expect(editor.getCursorScreenPosition()).toEqual [0, 2]

  describe "the I keybinding", ->
    beforeEach ->
      editor.getBuffer().setText("11\n  22\n")

    describe "at the end of a line", ->
      it "switches to insert mode at the beginning of the line", ->
        editor.setCursorScreenPosition([0,2])
        keydown('I', shift: true)

        expect(editorView).toHaveClass 'insert-mode'
        expect(editor.getCursorScreenPosition()).toEqual [0, 0]

      it "switches to insert mode after leading whitespace", ->
        editor.setCursorScreenPosition([1,4])
        keydown('I', shift: true)

        expect(editorView).toHaveClass 'insert-mode'
        expect(editor.getCursorScreenPosition()).toEqual [1, 2]

  describe "the J keybinding", ->
    beforeEach ->
      editor.getBuffer().setText("012\n    456\n")
      editor.setCursorScreenPosition([0, 1])

    describe "without repeating", ->
      beforeEach -> keydown('J', shift: true)

      it "joins the contents of the current line with the one below it", ->
        expect(editor.getText()).toBe "012 456\n"

    describe "with repeating", ->
      beforeEach ->
        editor.setText("12345\nabcde\nABCDE\nQWERT")
        editor.setCursorScreenPosition([1, 1])
        keydown('2')
        keydown('J', shift: true)

      describe "undo behavior", ->
        beforeEach -> keydown('u')

        it "handles repeats", ->
          expect(editor.getText()).toBe "12345\nabcde\nABCDE\nQWERT"

  describe "the > keybinding", ->
    beforeEach ->
      editor.setText("12345\nabcde\nABCDE")

    describe "on the last line", ->
      beforeEach ->
        editor.setCursorScreenPosition([2, 0])

      describe "when followed by a >", ->
        beforeEach ->
          keydown('>')
          keydown('>')

        it "indents the current line", ->
          expect(editor.getText()).toBe "12345\nabcde\n  ABCDE"
          expect(editor.getCursorScreenPosition()).toEqual [2, 2]

    describe "on the first line", ->
      beforeEach ->
        editor.setCursorScreenPosition([0, 0])

      describe "when followed by a >", ->
        beforeEach ->
          keydown('>')
          keydown('>')

        it "indents the current line", ->
          expect(editor.getText()).toBe "  12345\nabcde\nABCDE"
          expect(editor.getCursorScreenPosition()).toEqual [0, 2]

      describe "when followed by a repeating >", ->
        beforeEach ->
          keydown('3')
          keydown('>')
          keydown('>')

        it "indents multiple lines at once", ->
          expect(editor.getText()).toBe "  12345\n  abcde\n  ABCDE"
          expect(editor.getCursorScreenPosition()).toEqual [0, 2]

        describe "undo behavior", ->
          beforeEach -> keydown('u')

          it "outdents all three lines", ->
            expect(editor.getText()).toBe "12345\nabcde\nABCDE"

    describe "in visual mode", ->
      beforeEach ->
        editor.setCursorScreenPosition([0, 0])
        keydown('v', shift: true)
        keydown('>')

      it "indents the current line and remains in visual mode", ->
        expect(editorView).toHaveClass 'visual-mode'
        expect(editor.getText()).toBe "  12345\nabcde\nABCDE"
        expect(editor.getSelectedText()).toBe "  12345\n"

  describe "the < keybinding", ->
    beforeEach ->
      editor.setText("  12345\n  abcde\nABCDE")
      editor.setCursorScreenPosition([0, 0])

    describe "when followed by a <", ->
      beforeEach ->
        keydown('<')
        keydown('<')

      it "indents the current line", ->
        expect(editor.getText()).toBe "12345\n  abcde\nABCDE"
        expect(editor.getCursorScreenPosition()).toEqual [0, 0]

    describe "when followed by a repeating <", ->
      beforeEach ->
        keydown('2')
        keydown('<')
        keydown('<')

      it "indents multiple lines at once", ->
        expect(editor.getText()).toBe "12345\nabcde\nABCDE"
        expect(editor.getCursorScreenPosition()).toEqual [0, 0]

      describe "undo behavior", ->
        beforeEach -> keydown('u')

        it "indents both lines", ->
          expect(editor.getText()).toBe "  12345\n  abcde\nABCDE"

    describe "in visual mode", ->
      beforeEach ->
        keydown('v', shift: true)
        keydown('<')

      it "indents the current line and remains in visual mode", ->
        expect(editorView).toHaveClass 'visual-mode'
        expect(editor.getText()).toBe "12345\n  abcde\nABCDE"
        expect(editor.getSelectedText()).toBe "12345\n"

  describe "the = keybinding", ->
    oldGrammar = []

    beforeEach ->
      waitsForPromise ->
        atom.packages.activatePackage('language-javascript')

      oldGrammar = editor.getGrammar()
      editor.setText("foo\n  bar\n  baz")
      editor.setCursorScreenPosition([1, 0])

    describe "when used in a scope that supports auto-indent", ->
      beforeEach ->
        jsGrammar = atom.syntax.grammarForScopeName('source.js')
        editor.setGrammar(jsGrammar)

      afterEach ->
        editor.setGrammar(oldGrammar)

      describe "when followed by a =", ->
        beforeEach ->
          keydown('=')
          keydown('=')

        it "indents the current line", ->
          expect(editor.indentationForBufferRow(1)).toBe 0

      describe "when followed by a repeating =", ->
        beforeEach ->
          keydown('2')
          keydown('=')
          keydown('=')

        it "autoindents multiple lines at once", ->
          expect(editor.getText()).toBe "foo\nbar\nbaz"
          expect(editor.getCursorScreenPosition()).toEqual [1, 0]

        describe "undo behavior", ->
          beforeEach -> keydown('u')

          it "indents both lines", ->
            expect(editor.getText()).toBe "foo\n  bar\n  baz"

  describe "the . keybinding", ->
    beforeEach ->
      editor.setText("12\n34\n56\n78")
      editor.setCursorScreenPosition([0,0])

    it "repeats the last operation", ->
      keydown '2'
      keydown 'd'
      keydown 'd'
      keydown '.'

      expect(editor.getText()).toBe ""

    it "composes with motions", ->
      keydown 'd'
      keydown 'd'
      keydown '2'
      keydown '.'

      expect(editor.getText()).toBe "78"

  describe "the r keybinding", ->
    beforeEach ->
      editor.setText("12\n34\n\n")
      editor.setCursorBufferPosition([0,0])

    it "replaces a single character", ->
      keydown('r')
      commandModeInputKeydown('x')
      expect(editor.getText()).toBe 'x2\n34\n\n'

    it "composes properly with motions", ->
      keydown('2')
      keydown('r')
      commandModeInputKeydown('x')
      expect(editor.getText()).toBe 'xx\n34\n\n'

    it "does nothing on an empty line", ->
      editor.setCursorBufferPosition([2, 0])
      keydown('r')
      commandModeInputKeydown('x')
      expect(editor.getText()).toBe '12\n34\n\n'

    it "does nothing if asked to replace more characters than there are on a line", ->
      keydown('3')
      keydown('r')
      commandModeInputKeydown('x')
      expect(editor.getText()).toBe '12\n34\n\n'

  describe 'the m keybinding', ->
    beforeEach ->
      editor.setText('12\n34\n56\n')
      editor.setCursorBufferPosition([0,1])

    it 'marks a position', ->
      keydown('m')
      commandModeInputKeydown('a')
      expect(vimState.getMark('a')).toEqual [0,1]

  describe 'the ~ keybinding', ->
    beforeEach ->
      editor.setText('aBc')
      editor.setCursorBufferPosition([0, 0])

    it 'toggles the case and moves right', ->
      keydown('~')
      expect(editor.getText()).toBe 'ABc'
      expect(editor.getCursorScreenPosition()).toEqual [0, 1]

      keydown('~')
      expect(editor.getText()).toBe 'Abc'
      expect(editor.getCursorScreenPosition()).toEqual [0, 2]

      keydown('~')
      expect(editor.getText()).toBe 'AbC'
      expect(editor.getCursorScreenPosition()).toEqual [0, 2]

    it 'can be repeated', ->
      keydown('4')
      keydown('~')

      expect(editor.getText()).toBe 'AbC'
      expect(editor.getCursorScreenPosition()).toEqual [0, 2]

  describe "the i keybinding", ->
    beforeEach ->
      editor.setText('')
      editor.setCursorBufferPosition([0, 0])

    it "allows undoing an entire batch of typing", ->
      keydown 'i'
      editor.insertText("abc")
      keydown 'escape'
      keydown 'i'
      editor.insertText("def")
      keydown 'escape'
      expect(editor.getText()).toBe "abdefc"
      keydown 'u'
      expect(editor.getText()).toBe "abc"
      keydown 'u'
      expect(editor.getText()).toBe ""

    it "allows repeating typing", ->
      keydown 'i'
      editor.insertText("abc")
      keydown 'escape'
      keydown '.'
      editor.insertText("ababcc")

    # This one doesn't work because we can't simulate typing correctly,
    # and VimState#resetInputTransactions actually inspects buffer patches to
    # build patches for repeating
    xit "resets transactions for repeats after movement", ->
      editor.setCursorBufferPosition([0, 0])
      editor.insertText("abc\n123")
      keydown 'i'
      editor.insertText("def")
      editorView.trigger 'core:move-down'
      expect(editor.getCursorBufferPosition()).toEqual [1, 3]
      editor.insertText("456")
      keydown 'escape'
      editor.setCursorBufferPosition([0, 0])
      keydown '.'
      expect(editor.getText()).toEqual "456defabc\n456123"

  describe 'the a keybinding', ->
    beforeEach ->
      editor.setText('')
      editor.setCursorBufferPosition([0, 0])

    it "can be undone in one go", ->
      keydown 'a'
      editor.insertText("abc")
      keydown 'escape'
      expect(editor.getText()).toBe "abc"
      keydown 'u'
      expect(editor.getText()).toBe ""

    it "repeats correctly", ->
      keydown 'a'
      editor.insertText("abc")
      keydown 'escape'
      expect(editor.getText()).toBe "abc"
      keydown '.'
      expect(editor.getText()).toBe "abcabc"
