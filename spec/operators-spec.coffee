helpers = require './spec-helper'
settings = require '../lib/settings'

describe "Operators", ->
  [editor, editorElement, vimState] = []

  beforeEach ->
    vimMode = atom.packages.loadPackage('vim-mode')
    vimMode.activateResources()

    helpers.getEditorElement (element) ->
      editorElement = element
      editor = editorElement.getModel()
      vimState = editorElement.vimState
      vimState.activateNormalMode()
      vimState.resetNormalMode()

  keydown = (key, options={}) ->
    options.element ?= editorElement
    helpers.keydown(key, options)

  normalModeInputKeydown = (key, opts = {}) ->
    editor.normalModeInputView.editorElement.getModel().setText(key)

  describe "cancelling operations", ->
    it "throws an error when no operation is pending", ->
      # cancel operation pushes an empty input operation
      # doing this without a pending operation would throw an exception
      expect(-> vimState.pushOperations(new Input(''))).toThrow()

    it "cancels and cleans up properly", ->
      # make sure normalModeInputView is created
      keydown('/')
      expect(vimState.isOperatorPending()).toBe true
      editor.normalModeInputView.viewModel.cancel()

      expect(vimState.isOperatorPending()).toBe false
      expect(editor.normalModeInputView).toBe undefined

  describe "the x keybinding", ->
    describe "on a line with content", ->
      describe "without vim-mode.wrapLeftRightMotion", ->
        beforeEach ->
          editor.setText("abc\n012345\n\nxyz")
          editor.setCursorScreenPosition([1, 4])

        it "deletes a character", ->
          keydown('x')
          expect(editor.getText()).toBe 'abc\n01235\n\nxyz'
          expect(editor.getCursorScreenPosition()).toEqual [1, 4]
          expect(vimState.getRegister('"').text).toBe '4'

          keydown('x')
          expect(editor.getText()).toBe 'abc\n0123\n\nxyz'
          expect(editor.getCursorScreenPosition()).toEqual [1, 3]
          expect(vimState.getRegister('"').text).toBe '5'

          keydown('x')
          expect(editor.getText()).toBe 'abc\n012\n\nxyz'
          expect(editor.getCursorScreenPosition()).toEqual [1, 2]
          expect(vimState.getRegister('"').text).toBe '3'

          keydown('x')
          expect(editor.getText()).toBe 'abc\n01\n\nxyz'
          expect(editor.getCursorScreenPosition()).toEqual [1, 1]
          expect(vimState.getRegister('"').text).toBe '2'

          keydown('x')
          expect(editor.getText()).toBe 'abc\n0\n\nxyz'
          expect(editor.getCursorScreenPosition()).toEqual [1, 0]
          expect(vimState.getRegister('"').text).toBe '1'

          keydown('x')
          expect(editor.getText()).toBe 'abc\n\n\nxyz'
          expect(editor.getCursorScreenPosition()).toEqual [1, 0]
          expect(vimState.getRegister('"').text).toBe '0'

        it "deletes multiple characters with a count", ->
          keydown('2')
          keydown('x')
          expect(editor.getText()).toBe 'abc\n0123\n\nxyz'
          expect(editor.getCursorScreenPosition()).toEqual [1, 3]
          expect(vimState.getRegister('"').text).toBe '45'

          editor.setCursorScreenPosition([0, 1])
          keydown('3')
          keydown('x')
          expect(editor.getText()).toBe 'a\n0123\n\nxyz'
          expect(editor.getCursorScreenPosition()).toEqual [0, 0]
          expect(vimState.getRegister('"').text).toBe 'bc'

      describe "with multiple cursors", ->
        beforeEach ->
          editor.setText "abc\n012345\n\nxyz"
          editor.setCursorScreenPosition [1, 4]
          editor.addCursorAtBufferPosition [0, 1]

        it "is undone as one operation", ->
          keydown('x')
          expect(editor.getText()).toBe "ac\n01235\n\nxyz"
          keydown('u')
          expect(editor.getText()).toBe "abc\n012345\n\nxyz"

      describe "with vim-mode.wrapLeftRightMotion", ->
        beforeEach ->
          editor.setText("abc\n012345\n\nxyz")
          editor.setCursorScreenPosition([1, 4])
          atom.config.set('vim-mode.wrapLeftRightMotion', true)

        it "deletes a character", ->
          # copy of the earlier test because wrapLeftRightMotion should not affect it
          keydown('x')
          expect(editor.getText()).toBe 'abc\n01235\n\nxyz'
          expect(editor.getCursorScreenPosition()).toEqual [1, 4]
          expect(vimState.getRegister('"').text).toBe '4'

          keydown('x')
          expect(editor.getText()).toBe 'abc\n0123\n\nxyz'
          expect(editor.getCursorScreenPosition()).toEqual [1, 3]
          expect(vimState.getRegister('"').text).toBe '5'

          keydown('x')
          expect(editor.getText()).toBe 'abc\n012\n\nxyz'
          expect(editor.getCursorScreenPosition()).toEqual [1, 2]
          expect(vimState.getRegister('"').text).toBe '3'

          keydown('x')
          expect(editor.getText()).toBe 'abc\n01\n\nxyz'
          expect(editor.getCursorScreenPosition()).toEqual [1, 1]
          expect(vimState.getRegister('"').text).toBe '2'

          keydown('x')
          expect(editor.getText()).toBe 'abc\n0\n\nxyz'
          expect(editor.getCursorScreenPosition()).toEqual [1, 0]
          expect(vimState.getRegister('"').text).toBe '1'

          keydown('x')
          expect(editor.getText()).toBe 'abc\n\n\nxyz'
          expect(editor.getCursorScreenPosition()).toEqual [1, 0]
          expect(vimState.getRegister('"').text).toBe '0'

        it "deletes multiple characters and newlines with a count", ->
          atom.config.set('vim-mode.wrapLeftRightMotion', true)
          keydown('2')
          keydown('x')
          expect(editor.getText()).toBe 'abc\n0123\n\nxyz'
          expect(editor.getCursorScreenPosition()).toEqual [1, 3]
          expect(vimState.getRegister('"').text).toBe '45'

          editor.setCursorScreenPosition([0, 1])
          keydown('3')
          keydown('x')
          expect(editor.getText()).toBe 'a0123\n\nxyz'
          expect(editor.getCursorScreenPosition()).toEqual [0, 1]
          expect(vimState.getRegister('"').text).toBe 'bc\n'

          keydown('7')
          keydown('x')
          expect(editor.getText()).toBe 'ayz'
          expect(editor.getCursorScreenPosition()).toEqual [0, 1]
          expect(vimState.getRegister('"').text).toBe '0123\n\nx'

    describe "on an empty line", ->
      beforeEach ->
        editor.setText("abc\n012345\n\nxyz")
        editor.setCursorScreenPosition([2, 0])

      it "deletes nothing on an empty line when vim-mode.wrapLeftRightMotion is false", ->
        atom.config.set('vim-mode.wrapLeftRightMotion', false)
        keydown('x')
        expect(editor.getText()).toBe "abc\n012345\n\nxyz"
        expect(editor.getCursorScreenPosition()).toEqual [2, 0]

      it "deletes an empty line when vim-mode.wrapLeftRightMotion is true", ->
        atom.config.set('vim-mode.wrapLeftRightMotion', true)
        keydown('x')
        expect(editor.getText()).toBe "abc\n012345\nxyz"
        expect(editor.getCursorScreenPosition()).toEqual [2, 0]

  describe "the X keybinding", ->
    describe "on a line with content", ->
      beforeEach ->
        editor.setText("ab\n012345")
        editor.setCursorScreenPosition([1, 2])

      it "deletes a character", ->
        keydown('X', shift: true)
        expect(editor.getText()).toBe 'ab\n02345'
        expect(editor.getCursorScreenPosition()).toEqual [1, 1]
        expect(vimState.getRegister('"').text).toBe '1'

        keydown('X', shift: true)
        expect(editor.getText()).toBe 'ab\n2345'
        expect(editor.getCursorScreenPosition()).toEqual [1, 0]
        expect(vimState.getRegister('"').text).toBe '0'

        keydown('X', shift: true)
        expect(editor.getText()).toBe 'ab\n2345'
        expect(editor.getCursorScreenPosition()).toEqual [1, 0]
        expect(vimState.getRegister('"').text).toBe '0'

        atom.config.set('vim-mode.wrapLeftRightMotion', true)
        keydown('X', shift: true)
        expect(editor.getText()).toBe 'ab2345'
        expect(editor.getCursorScreenPosition()).toEqual [0, 2]
        expect(vimState.getRegister('"').text).toBe '\n'

    describe "on an empty line", ->
      beforeEach ->
        editor.setText("012345\n\nabcdef")
        editor.setCursorScreenPosition([1, 0])

      it "deletes nothing when vim-mode.wrapLeftRightMotion is false", ->
        atom.config.set('vim-mode.wrapLeftRightMotion', false)
        keydown('X', shift: true)
        expect(editor.getText()).toBe "012345\n\nabcdef"
        expect(editor.getCursorScreenPosition()).toEqual [1, 0]

      it "deletes the newline when wrapLeftRightMotion is true", ->
        atom.config.set('vim-mode.wrapLeftRightMotion', true)
        keydown('X', shift: true)
        expect(editor.getText()).toBe "012345\nabcdef"
        expect(editor.getCursorScreenPosition()).toEqual [0, 5]

  describe "the s keybinding", ->
    beforeEach ->
      editor.setText('012345')
      editor.setCursorScreenPosition([0, 1])

    it "deletes the character to the right and enters insert mode", ->
      keydown('s')
      expect(editorElement.classList.contains('insert-mode')).toBe(true)
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
      expect(editor.getSelectedText()).toBe ''

    describe "in visual mode", ->
      beforeEach ->
        keydown('v')
        editor.selectRight()
        keydown('s')

      it "deletes the selected characters and enters insert mode", ->
        expect(editorElement.classList.contains('insert-mode')).toBe(true)
        expect(editor.getText()).toBe '0345'
        expect(editor.getCursorScreenPosition()).toEqual [0, 1]
        expect(vimState.getRegister('"').text).toBe '12'

  describe "the S keybinding", ->
    beforeEach ->
      editor.setText("12345\nabcde\nABCDE")
      editor.setCursorScreenPosition([1, 3])

    it "deletes the entire line and enters insert mode", ->
      keydown('S', shift: true)
      expect(editorElement.classList.contains('insert-mode')).toBe(true)
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
      expect(editor.getSelectedText()).toBe ''

    it "works when the cursor's goal column is greater than its current column", ->
      editor.setText("\n12345")
      editor.setCursorBufferPosition([1, Infinity])
      editor.moveUp()
      keydown("S", shift: true)
      expect(editor.getText()).toBe("\n12345")

    # Can't be tested without setting grammar of test buffer
    xit "respects indentation", ->

  describe "the d keybinding", ->
    it "enters operator-pending mode", ->
      keydown('d')
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(true)
      expect(editorElement.classList.contains('normal-mode')).toBe(false)

    describe "when followed by a d", ->
      it "deletes the current line and exits operator-pending mode", ->
        editor.setText("12345\nabcde\n\nABCDE")
        editor.setCursorScreenPosition([1, 1])

        keydown('d')
        keydown('d')

        expect(editor.getText()).toBe "12345\n\nABCDE"
        expect(editor.getCursorScreenPosition()).toEqual [1, 0]
        expect(vimState.getRegister('"').text).toBe "abcde\n"
        expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
        expect(editorElement.classList.contains('normal-mode')).toBe(true)

      it "deletes the last line", ->
        editor.setText("12345\nabcde\nABCDE")
        editor.setCursorScreenPosition([2, 1])

        keydown('d')
        keydown('d')

        expect(editor.getText()).toBe "12345\nabcde\n"
        expect(editor.getCursorScreenPosition()).toEqual [2, 0]

      it "leaves the cursor on the first nonblank character", ->
        editor.setText("12345\n  abcde\n")
        editor.setCursorScreenPosition([0, 4])

        keydown('d')
        keydown('d')

        expect(editor.getText()).toBe "  abcde\n"
        expect(editor.getCursorScreenPosition()).toEqual [0, 2]

    describe "undo behavior", ->
      beforeEach ->
        editor.setText("12345\nabcde\nABCDE\nQWERT")
        editor.setCursorScreenPosition([1, 1])

      it "undoes both lines", ->
        keydown('d')
        keydown('2')
        keydown('d')

        keydown('u')

        expect(editor.getText()).toBe "12345\nabcde\nABCDE\nQWERT"
        expect(editor.getSelectedText()).toBe ''

      describe "with multiple cursors", ->
        beforeEach ->
          editor.setCursorBufferPosition([1, 1])
          editor.addCursorAtBufferPosition([0, 0])

        it "is undone as one operation", ->
          keydown('d')
          keydown('l')

          keydown('u')

          expect(editor.getText()).toBe "12345\nabcde\nABCDE\nQWERT"
          expect(editor.getSelectedText()).toBe ''

    describe "when followed by a w", ->
      it "deletes the next word until the end of the line and exits operator-pending mode", ->
        editor.setText("abcd efg\nabc")
        editor.setCursorScreenPosition([0, 5])

        keydown('d')
        keydown('w')

        # Incompatibility with VIM. In vim, `w` behaves differently as an
        # operator than as a motion; it stops at the end of a line.expect(editor.getText()).toBe "abcd abc"
        expect(editor.getText()).toBe "abcd abc"
        expect(editor.getCursorScreenPosition()).toEqual [0, 5]

        expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
        expect(editorElement.classList.contains('normal-mode')).toBe(true)

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
        expect(editorElement.classList.contains('operator-pending-mode')).toBe(true)
        keydown('i')
        keydown('w')

        expect(editor.getText()).toBe "12345  ABCDE"
        expect(editor.getCursorScreenPosition()).toEqual [0, 6]
        expect(vimState.getRegister('"').text).toBe "abcde"
        expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
        expect(editorElement.classList.contains('normal-mode')).toBe(true)

    describe "when followed by a j", ->
      originalText = "12345\nabcde\nABCDE\n"

      beforeEach ->
        editor.setText(originalText)

      describe "on the beginning of the file", ->
        it "deletes the next two lines", ->
          editor.setCursorScreenPosition([0, 0])
          keydown('d')
          keydown('j')
          expect(editor.getText()).toBe("ABCDE\n")

      describe "on the end of the file", ->
        it "deletes nothing", ->
          editor.setCursorScreenPosition([4, 0])
          keydown('d')
          keydown('j')
          expect(editor.getText()).toBe(originalText)

      describe "on the middle of second line", ->
        it "deletes the last two lines", ->
          editor.setCursorScreenPosition([1, 2])
          keydown('d')
          keydown('j')
          expect(editor.getText()).toBe("12345\n")

    describe "when followed by an k", ->
      originalText = "12345\nabcde\nABCDE"

      beforeEach ->
        editor.setText(originalText)

      describe "on the end of the file", ->
        it "deletes the bottom two lines", ->
          editor.setCursorScreenPosition([2, 4])
          keydown('d')
          keydown('k')
          expect(editor.getText()).toBe("12345\n")

      describe "on the beginning of the file", ->
        xit "deletes nothing", ->
          editor.setCursorScreenPosition([0, 0])
          keydown('d')
          keydown('k')
          expect(editor.getText()).toBe(originalText)

      describe "when on the middle of second line", ->
        it "deletes the first two lines", ->
          editor.setCursorScreenPosition([1, 2])
          keydown('d')
          keydown('k')
          expect(editor.getText()).toBe("ABCDE")

    describe "when followed by a G", ->
      beforeEach ->
        originalText = "12345\nabcde\nABCDE"
        editor.setText(originalText)

      describe "on the beginning of the second line", ->
        it "deletes the bottom two lines", ->
          editor.setCursorScreenPosition([1, 0])
          keydown('d')
          keydown('G', shift: true)
          expect(editor.getText()).toBe("12345\n")

      describe "on the middle of the second line", ->
        it "deletes the bottom two lines", ->
          editor.setCursorScreenPosition([1, 2])
          keydown('d')
          keydown('G', shift: true)
          expect(editor.getText()).toBe("12345\n")

    describe "when followed by a goto line G", ->
      beforeEach ->
        originalText = "12345\nabcde\nABCDE"
        editor.setText(originalText)

      describe "on the beginning of the second line", ->
        it "deletes the bottom two lines", ->
          editor.setCursorScreenPosition([1, 0])
          keydown('d')
          keydown('2')
          keydown('G', shift: true)
          expect(editor.getText()).toBe("12345\nABCDE")

      describe "on the middle of the second line", ->
        it "deletes the bottom two lines", ->
          editor.setCursorScreenPosition([1, 2])
          keydown('d')
          keydown('2')
          keydown('G', shift: true)
          expect(editor.getText()).toBe("12345\nABCDE")

    describe "when followed by a t)", ->
      describe "with the entire line yanked before", ->
        beforeEach ->
          editor.setText("test (xyz)")
          editor.setCursorScreenPosition([0, 6])

        it "deletes until the closing parenthesis", ->
          keydown('y')
          keydown('y')
          keydown('d')
          keydown('t')
          normalModeInputKeydown(')')
          expect(editor.getText()).toBe("test ()")
          expect(editor.getCursorScreenPosition()).toEqual [0, 6]

    describe "with multiple cursors", ->
      it "deletes each selection", ->
        editor.setText("abcd\n1234\nABCD\n")
        editor.setCursorBufferPosition([0, 1])
        editor.addCursorAtBufferPosition([1, 2])
        editor.addCursorAtBufferPosition([2, 3])

        keydown('d')
        keydown('e')

        expect(editor.getText()).toBe "a\n12\nABC"
        expect(editor.getCursorBufferPositions()).toEqual [
          [0, 0],
          [1, 1],
          [2, 2],
        ]

      it "doesn't delete empty selections", ->
        editor.setText("abcd\nabc\nabd")
        editor.setCursorBufferPosition([0, 0])
        editor.addCursorAtBufferPosition([1, 0])
        editor.addCursorAtBufferPosition([2, 0])

        keydown('d')
        keydown('t')
        normalModeInputKeydown('d')

        expect(editor.getText()).toBe "d\nabc\nd"
        expect(editor.getCursorBufferPositions()).toEqual [
          [0, 0],
          [1, 0],
          [2, 0],
        ]

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
      describe "with autoindent", ->
        beforeEach ->
          editor.setText("12345\n  abcde\nABCDE")
          editor.setCursorScreenPosition([1, 1])
          spyOn(editor, 'shouldAutoIndent').andReturn(true)
          spyOn(editor, 'autoIndentBufferRow').andCallFake (line) ->
            editor.indent()
          spyOn(editor.languageMode, 'suggestedIndentForLineAtBufferRow').andCallFake -> 1

        it "deletes the current line and enters insert mode", ->
          editor.setCursorScreenPosition([1, 1])

          keydown('c')
          keydown('c')

          expect(editor.getText()).toBe "12345\n  \nABCDE"
          expect(editor.getCursorScreenPosition()).toEqual [1, 2]
          expect(editorElement.classList.contains('normal-mode')).toBe(false)
          expect(editorElement.classList.contains('insert-mode')).toBe(true)

        it "is repeatable", ->
          keydown('c')
          keydown('c')
          editor.insertText("abc")
          keydown 'escape'
          expect(editor.getText()).toBe "12345\n  abc\nABCDE"
          editor.setCursorScreenPosition([2, 3])
          keydown '.'
          expect(editor.getText()).toBe "12345\n  abc\n  abc\n"

        it "is undoable", ->
          keydown('c')
          keydown('c')
          editor.insertText("abc")
          keydown 'escape'
          expect(editor.getText()).toBe "12345\n  abc\nABCDE"
          keydown 'u'
          expect(editor.getText()).toBe "12345\n  abcde\nABCDE"
          expect(editor.getSelectedText()).toBe ''

      describe "when the cursor is on the last line", ->
        it "deletes the line's content and enters insert mode on the last line", ->
          editor.setCursorScreenPosition([2, 1])

          keydown('c')
          keydown('c')

          expect(editor.getText()).toBe "12345\nabcde\n\n"
          expect(editor.getCursorScreenPosition()).toEqual [2, 0]
          expect(editorElement.classList.contains('normal-mode')).toBe(false)
          expect(editorElement.classList.contains('insert-mode')).toBe(true)

      describe "when the cursor is on the only line", ->
        it "deletes the line's content and enters insert mode", ->
          editor.setText("12345")
          editor.setCursorScreenPosition([0, 2])

          keydown('c')
          keydown('c')

          expect(editor.getText()).toBe ""
          expect(editor.getCursorScreenPosition()).toEqual [0, 0]
          expect(editorElement.classList.contains('normal-mode')).toBe(false)
          expect(editorElement.classList.contains('insert-mode')).toBe(true)

    describe "when followed by i w", ->
      it "undo's and redo's completely", ->
        editor.setCursorScreenPosition([1, 1])

        keydown('c')
        keydown('i')
        keydown('w')
        expect(editor.getText()).toBe "12345\n\nABCDE"
        expect(editor.getCursorScreenPosition()).toEqual [1, 0]
        expect(editorElement.classList.contains('insert-mode')).toBe(true)

        # Just cannot get "typing" to work correctly in test.
        editor.setText("12345\nfg\nABCDE")
        keydown('escape')
        expect(editorElement.classList.contains('normal-mode')).toBe(true)
        expect(editor.getText()).toBe "12345\nfg\nABCDE"

        keydown('u')
        expect(editor.getText()).toBe "12345\nabcde\nABCDE"
        keydown('r', ctrl: true)
        expect(editor.getText()).toBe "12345\nfg\nABCDE"

    describe "when followed by a w", ->
      it "changes the word", ->
        editor.setText("word1 word2 word3")
        editor.setCursorBufferPosition([0, "word1 w".length])

        keydown("c")
        keydown("w")
        keydown("escape")

        expect(editor.getText()).toBe "word1 w word3"

    describe "when followed by a G", ->
      beforeEach ->
        originalText = "12345\nabcde\nABCDE"
        editor.setText(originalText)

      describe "on the beginning of the second line", ->
        it "deletes the bottom two lines", ->
          editor.setCursorScreenPosition([1, 0])
          keydown('c')
          keydown('G', shift: true)
          keydown('escape')
          expect(editor.getText()).toBe("12345\n\n")

      describe "on the middle of the second line", ->
        it "deletes the bottom two lines", ->
          editor.setCursorScreenPosition([1, 2])
          keydown('c')
          keydown('G', shift: true)
          keydown('escape')
          expect(editor.getText()).toBe("12345\n\n")

    describe "when followed by a %", ->
      beforeEach ->
        editor.setText("12345(67)8\nabc(d)e\nA()BCDE")

      describe "before brackets or on the first one", ->
        beforeEach ->
          editor.setCursorScreenPosition([0, 1])
          editor.addCursorAtScreenPosition([1, 1])
          editor.addCursorAtScreenPosition([2, 1])
          keydown('c')
          keydown('%')
          editor.insertText('x')

        it "replaces inclusively until matching bracket", ->
          expect(editor.getText()).toBe("1x8\naxe\nAxBCDE")
          expect(vimState.mode).toBe "insert"

        it "undoes correctly with u", ->
          keydown('escape')
          expect(vimState.mode).toBe "normal"
          keydown 'u'
          expect(editor.getText()).toBe("12345(67)8\nabc(d)e\nA()BCDE")

      describe "inside brackets or on the ending one", ->
        it "replaces inclusively backwards until matching bracket", ->
          editor.setCursorScreenPosition([0, 6])
          editor.addCursorAtScreenPosition([1, 5])
          editor.addCursorAtScreenPosition([2, 2])
          keydown('c')
          keydown('%')
          editor.insertText('x')
          expect(editor.getText()).toBe("12345x7)8\nabcxe\nAxBCDE")
          expect(vimState.mode).toBe "insert"

      describe "after or without brackets", ->
        it "deletes nothing", ->
          editor.setText("12345(67)8\nabc(d)e\nABCDE")
          editor.setCursorScreenPosition([0, 9])
          editor.addCursorAtScreenPosition([2, 2])
          keydown('c')
          keydown('%')
          expect(editor.getText()).toBe("12345(67)8\nabc(d)e\nABCDE")
          expect(vimState.mode).toBe "normal"

      describe "repetition with .", ->
        beforeEach ->
          editor.setCursorScreenPosition([0, 1])
          keydown('c')
          keydown('%')
          editor.insertText('x')
          keydown('escape')

        it "repeats correctly before a bracket", ->
          editor.setCursorScreenPosition([1, 0])
          keydown('.')
          expect(editor.getText()).toBe("1x8\nxe\nA()BCDE")
          expect(vimState.mode).toBe "normal"

        it "repeats correctly on the opening bracket", ->
          editor.setCursorScreenPosition([1, 3])
          keydown('.')
          expect(editor.getText()).toBe("1x8\nabcxe\nA()BCDE")
          expect(vimState.mode).toBe "normal"

        it "repeats correctly inside brackets", ->
          editor.setCursorScreenPosition([1, 4])
          keydown('.')
          expect(editor.getText()).toBe("1x8\nabcx)e\nA()BCDE")
          expect(vimState.mode).toBe "normal"

        it "repeats correctly on the closing bracket", ->
          editor.setCursorScreenPosition([1, 5])
          keydown('.')
          expect(editor.getText()).toBe("1x8\nabcxe\nA()BCDE")
          expect(vimState.mode).toBe "normal"

        it "does nothing when repeated after a bracket", ->
          editor.setCursorScreenPosition([2, 3])
          keydown('.')
          expect(editor.getText()).toBe("1x8\nabc(d)e\nA()BCDE")
          expect(vimState.mode).toBe "normal"

    describe "when followed by a goto line G", ->
      beforeEach ->
        editor.setText "12345\nabcde\nABCDE"

      describe "on the beginning of the second line", ->
        it "deletes all the text on the line", ->
          editor.setCursorScreenPosition([1, 0])
          keydown('c')
          keydown('2')
          keydown('G', shift: true)
          keydown('escape')
          expect(editor.getText()).toBe("12345\n\nABCDE")

      describe "on the middle of the second line", ->
        it "deletes all the text on the line", ->
          editor.setCursorScreenPosition([1, 2])
          keydown('c')
          keydown('2')
          keydown('G', shift: true)
          keydown('escape')
          expect(editor.getText()).toBe("12345\n\nABCDE")

    describe "in visual mode", ->
      beforeEach ->
        editor.setText "123456789\nabcde\nfghijklmnopq\nuvwxyz"
        editor.setCursorScreenPosition [1, 1]

      describe "with characterwise selection on a single line", ->
        it "repeats with .", ->
          keydown 'v'
          keydown '2'
          keydown 'l'
          keydown 'c'
          editor.insertText "ab"
          keydown 'escape'
          expect(editor.getText()).toBe "123456789\naabe\nfghijklmnopq\nuvwxyz"

          editor.setCursorScreenPosition [0, 1]
          keydown '.'
          expect(editor.getText()).toBe "1ab56789\naabe\nfghijklmnopq\nuvwxyz"

        it "repeats shortened with . near the end of the line", ->
          editor.setCursorScreenPosition [0, 2]
          keydown 'v'
          keydown '4'
          keydown 'l'
          keydown 'c'
          editor.insertText "ab"
          keydown 'escape'
          expect(editor.getText()).toBe "12ab89\nabcde\nfghijklmnopq\nuvwxyz"

          editor.setCursorScreenPosition [1, 3]
          keydown '.'
          expect(editor.getText()).toBe "12ab89\nabcab\nfghijklmnopq\nuvwxyz"

        it "repeats shortened with . near the end of the line regardless of whether motion wrapping is enabled", ->
          atom.config.set('vim-mode.wrapLeftRightMotion', true)
          editor.setCursorScreenPosition [0, 2]
          keydown 'v'
          keydown '4'
          keydown 'l'
          keydown 'c'
          editor.insertText "ab"
          keydown 'escape'
          expect(editor.getText()).toBe "12ab89\nabcde\nfghijklmnopq\nuvwxyz"

          editor.setCursorScreenPosition [1, 3]
          keydown '.'
          # this differs from VIM, which would eat the \n before fghij...
          expect(editor.getText()).toBe "12ab89\nabcab\nfghijklmnopq\nuvwxyz"

      describe "is repeatable with characterwise selection over multiple lines", ->
        it "repeats with .", ->
          keydown 'v'
          keydown 'j'
          keydown '3'
          keydown 'l'
          keydown 'c'
          editor.insertText "x"
          keydown 'escape'
          expect(editor.getText()).toBe "123456789\naxklmnopq\nuvwxyz"

          editor.setCursorScreenPosition [0, 1]
          keydown '.'
          expect(editor.getText()).toBe "1xnopq\nuvwxyz"

        it "repeats shortened with . near the end of the line", ->
          # this behaviour is unlike VIM, see #737
          keydown 'v'
          keydown 'j'
          keydown '6'
          keydown 'l'
          keydown 'c'
          editor.insertText "x"
          keydown 'escape'
          expect(editor.getText()).toBe "123456789\naxnopq\nuvwxyz"

          editor.setCursorScreenPosition [0, 1]
          keydown '.'
          expect(editor.getText()).toBe "1x\nuvwxyz"

      describe "is repeatable with linewise selection", ->
        describe "with one line selected", ->
          it "repeats with .", ->
            keydown 'V', shift: true
            keydown 'c'
            editor.insertText "x"
            keydown 'escape'
            expect(editor.getText()).toBe "123456789\nx\nfghijklmnopq\nuvwxyz"

            editor.setCursorScreenPosition [0, 7]
            keydown '.'
            expect(editor.getText()).toBe "x\nx\nfghijklmnopq\nuvwxyz"

            editor.setCursorScreenPosition [2, 0]
            keydown '.'
            expect(editor.getText()).toBe "x\nx\nx\nuvwxyz"

        describe "with multiple lines selected", ->
          it "repeats with .", ->
            keydown 'V', shift: true
            keydown 'j'
            keydown 'c'
            editor.insertText "x"
            keydown 'escape'
            expect(editor.getText()).toBe "123456789\nx\nuvwxyz"

            editor.setCursorScreenPosition [0, 7]
            keydown '.'
            expect(editor.getText()).toBe "x\nuvwxyz"

          it "repeats shortened with . near the end of the file", ->
            keydown 'V', shift: true
            keydown 'j'
            keydown 'c'
            editor.insertText "x"
            keydown 'escape'
            expect(editor.getText()).toBe "123456789\nx\nuvwxyz"

            editor.setCursorScreenPosition [1, 7]
            keydown '.'
            expect(editor.getText()).toBe "123456789\nx\n"

      xdescribe "is repeatable with block selection", ->
        # there is no block selection yet

  describe "the C keybinding", ->
    beforeEach ->
      editor.getBuffer().setText("012\n")
      editor.setCursorScreenPosition([0, 1])
      keydown('C', shift: true)

    it "deletes the contents until the end of the line and enters insert mode", ->
      expect(editor.getText()).toBe "0\n"
      expect(editor.getCursorScreenPosition()).toEqual [0, 1]
      expect(editorElement.classList.contains('normal-mode')).toBe(false)
      expect(editorElement.classList.contains('insert-mode')).toBe(true)

  describe "the y keybinding", ->
    beforeEach ->
      editor.getBuffer().setText("012 345\nabc\ndefg\n")
      editor.setCursorScreenPosition([0, 4])
      vimState.setRegister('"', text: '345')

    describe "when selected lines in visual linewise mode", ->
      beforeEach ->
        keydown('V', shift: true)
        keydown('j')
        keydown('y')

      it "is in linewise motion", ->
        expect(vimState.getRegister('"').type).toEqual "linewise"

      it "saves the lines to the default register", ->
        expect(vimState.getRegister('"').text).toBe "012 345\nabc\n"

      it "places the cursor at the beginning of the selection", ->
        expect(editor.getCursorBufferPositions()).toEqual([[0, 0]])

    describe "when followed by a second y ", ->
      beforeEach ->
        keydown('y')
        keydown('y')

      it "saves the line to the default register", ->
        expect(vimState.getRegister('"').text).toBe "012 345\n"

      it "leaves the cursor at the starting position", ->
        expect(editor.getCursorScreenPosition()).toEqual [0, 4]

    describe "when useClipboardAsDefaultRegister enabled", ->
      it "writes to clipboard", ->
        atom.config.set 'vim-mode.useClipboardAsDefaultRegister', true
        keydown('y')
        keydown('y')
        expect(atom.clipboard.read()).toBe '012 345\n'

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

      it "appends the line to the A register", ->
        keydown('"')
        keydown('A', shift: true)
        keydown('y')
        keydown('y')
        expect(vimState.getRegister('a').text).toBe "012 345\n012 345\n"

    describe "with a forward motion", ->
      beforeEach ->
        keydown('y')
        keydown('e')

      it "saves the selected text to the default register", ->
        expect(vimState.getRegister('"').text).toBe '345'

      it "leaves the cursor at the starting position", ->
        expect(editor.getCursorScreenPosition()).toEqual [0, 4]

      it "does not yank when motion fails", ->
        keydown('y')
        keydown('t')
        normalModeInputKeydown('x')
        expect(vimState.getRegister('"').text).toBe '345'

    describe "with a text object", ->
      it "moves the cursor to the beginning of the text object", ->
        editor.setCursorBufferPosition([0, 5])
        keydown("y")
        keydown("i")
        keydown("w")
        expect(editor.getCursorBufferPositions()).toEqual([[0, 4]])

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

    describe "with an up motion", ->
      beforeEach ->
        editor.setCursorScreenPosition([2, 2])
        keydown 'y'
        keydown 'k'

      it "saves both full lines to the default register", ->
        expect(vimState.getRegister('"').text).toBe "abc\ndefg\n"

      it "puts the cursor on the first line and the original column", ->
        expect(editor.getCursorScreenPosition()).toEqual [1, 2]

    describe "when followed by a G", ->
      beforeEach ->
        originalText = "12345\nabcde\nABCDE"
        editor.setText(originalText)

      describe "on the beginning of the second line", ->
        it "deletes the bottom two lines", ->
          editor.setCursorScreenPosition([1, 0])
          keydown('y')
          keydown('G', shift: true)
          keydown('P', shift: true)
          expect(editor.getText()).toBe("12345\nabcde\nABCDE\nabcde\nABCDE")

      describe "on the middle of the second line", ->
        it "deletes the bottom two lines", ->
          editor.setCursorScreenPosition([1, 2])
          keydown('y')
          keydown('G', shift: true)
          keydown('P', shift: true)
          expect(editor.getText()).toBe("12345\nabcde\nABCDE\nabcde\nABCDE")

    describe "when followed by a goto line G", ->
      beforeEach ->
        originalText = "12345\nabcde\nABCDE"
        editor.setText(originalText)

      describe "on the beginning of the second line", ->
        it "deletes the bottom two lines", ->
          editor.setCursorScreenPosition([1, 0])
          keydown('y')
          keydown('2')
          keydown('G', shift: true)
          keydown('P', shift: true)
          expect(editor.getText()).toBe("12345\nabcde\nabcde\nABCDE")

      describe "on the middle of the second line", ->
        it "deletes the bottom two lines", ->
          editor.setCursorScreenPosition([1, 2])
          keydown('y')
          keydown('2')
          keydown('G', shift: true)
          keydown('P', shift: true)
          expect(editor.getText()).toBe("12345\nabcde\nabcde\nABCDE")

    describe "with multiple cursors", ->
      it "moves each cursor and copies the last selection's text", ->
        editor.setText "  abcd\n  1234"
        editor.setCursorBufferPosition([0, 0])
        editor.addCursorAtBufferPosition([1, 5])

        keydown("y")
        keydown("^")

        expect(vimState.getRegister('"').text).toBe '123'
        expect(editor.getCursorBufferPositions()).toEqual [[0, 0], [1, 2]]

    describe "in a long file", ->
      beforeEach ->
        jasmine.attachToDOM(editorElement)
        editorElement.setHeight(400)
        editorElement.style.lineHeight = "10px"
        editorElement.style.font = "16px monospace"
        atom.views.performDocumentPoll()

        text = ""
        for i in [1..200]
          text += "#{i}\n"
        editor.setText(text)

      describe "yanking many lines forward", ->
        it "does not scroll the window", ->
          editor.setCursorBufferPosition [40, 1]
          previousScrollTop = editorElement.getScrollTop()

          # yank many lines
          keydown('y')
          keydown('1')
          keydown('6')
          keydown('0')
          keydown('G', shift: true)

          expect(editorElement.getScrollTop()).toEqual(previousScrollTop)
          expect(editor.getCursorBufferPosition()).toEqual [40, 1]
          expect(vimState.getRegister('"').text.split('\n').length).toBe 121

      describe "yanking many lines backwards", ->
        it "scrolls the window", ->
          editor.setCursorBufferPosition [140, 1]
          previousScrollTop = editorElement.getScrollTop()

          # yank many lines
          keydown('y')
          keydown('6')
          keydown('0')
          keydown('G', shift: true)

          expect(editorElement.getScrollTop()).toNotEqual previousScrollTop
          expect(editor.getCursorBufferPosition()).toEqual [59, 1]
          expect(vimState.getRegister('"').text.split('\n').length).toBe 83

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
        atom.clipboard.write "clip"

      describe "from the default register", ->
        beforeEach -> keydown('p')

        it "inserts the contents", ->
          expect(editor.getText()).toBe "034512\n"
          expect(editor.getCursorScreenPosition()).toEqual [0, 3]

      describe "at the end of a line", ->
        beforeEach ->
          editor.setCursorScreenPosition [0, 2]
          keydown('p')

        it "positions cursor correctly", ->
          expect(editor.getText()).toBe "012345\n"
          expect(editor.getCursorScreenPosition()).toEqual [0, 5]

      describe "when useClipboardAsDefaultRegister enabled", ->
        it "inserts contents from clipboard", ->
          atom.config.set 'vim-mode.useClipboardAsDefaultRegister', true
          keydown('p')
          expect(editor.getText()).toBe "0clip12\n"

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
      expect(editorElement.classList.contains('insert-mode')).toBe(true)

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
      expect(editorElement.classList.contains('insert-mode')).toBe(true)
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
        expect(editorElement.classList.contains('insert-mode')).toBe(true)

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
        editor.setCursorScreenPosition([0, 0])
        keydown('A', shift: true)

        expect(editorElement.classList.contains('insert-mode')).toBe(true)
        expect(editor.getCursorScreenPosition()).toEqual [0, 2]

      it "repeats always as insert at the end of the line", ->
        editor.setCursorScreenPosition([0, 0])
        keydown('A', shift: true)
        editor.insertText("abc")
        keydown 'escape'
        editor.setCursorScreenPosition([1, 0])
        keydown '.'

        expect(editor.getText()).toBe "11abc\n22abc\n"
        expect(editorElement.classList.contains('insert-mode')).toBe(false)
        expect(editor.getCursorScreenPosition()).toEqual [1, 4]

  describe "the I keybinding", ->
    beforeEach ->
      editor.getBuffer().setText("11\n  22\n")

    describe "at the end of a line", ->
      it "switches to insert mode at the beginning of the line", ->
        editor.setCursorScreenPosition([0, 2])
        keydown('I', shift: true)

        expect(editorElement.classList.contains('insert-mode')).toBe(true)
        expect(editor.getCursorScreenPosition()).toEqual [0, 0]

      it "switches to insert mode after leading whitespace", ->
        editor.setCursorScreenPosition([1, 4])
        keydown('I', shift: true)

        expect(editorElement.classList.contains('insert-mode')).toBe(true)
        expect(editor.getCursorScreenPosition()).toEqual [1, 2]

      it "repeats always as insert at the first character of the line", ->
        editor.setCursorScreenPosition([0, 2])
        keydown('I', shift: true)
        editor.insertText("abc")
        keydown 'escape'
        expect(editor.getCursorScreenPosition()).toEqual [0, 2]
        editor.setCursorScreenPosition([1, 4])
        keydown '.'

        expect(editor.getText()).toBe "abc11\n  abc22\n"
        expect(editorElement.classList.contains('insert-mode')).toBe(false)
        expect(editor.getCursorScreenPosition()).toEqual [1, 4]

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

    describe "in visual mode linewise", ->
      beforeEach ->
        editor.setCursorScreenPosition([0, 0])
        keydown('v', shift: true)
        keydown('j')

      describe "single indent multiple lines", ->
        beforeEach ->
          keydown('>')

        it "indents both lines once and exits visual mode", ->
          expect(editorElement.classList.contains('normal-mode')).toBe(true)
          expect(editor.getText()).toBe "  12345\n  abcde\nABCDE"
          expect(editor.getSelectedBufferRanges()).toEqual [ [[0, 2], [0, 2]] ]

        it "allows repeating the operation", ->
          keydown('.')
          expect(editor.getText()).toBe "    12345\n    abcde\nABCDE"

      describe "multiple indent multiple lines", ->
        beforeEach ->
          keydown('2')
          keydown('>')

        it "indents both lines twice and exits visual mode", ->
          expect(editorElement.classList.contains('normal-mode')).toBe(true)
          expect(editor.getText()).toBe "    12345\n    abcde\nABCDE"
          expect(editor.getSelectedBufferRanges()).toEqual [ [[0, 4], [0, 4]] ]

    describe "with multiple selections", ->
      beforeEach ->
        editor.setCursorScreenPosition([1, 3])
        keydown('v')
        keydown('j')
        editor.addCursorAtScreenPosition([0, 0])

      it "indents the lines and keeps the cursors", ->
        keydown('>')
        expect(editor.getText()).toBe "  12345\n  abcde\n  ABCDE"
        expect(editor.getCursorScreenPositions()).toEqual [[1, 2], [0, 2]]

  describe "the < keybinding", ->
    beforeEach ->
      editor.setText("    12345\n    abcde\nABCDE")
      editor.setCursorScreenPosition([0, 0])

    describe "when followed by a <", ->
      beforeEach ->
        keydown('<')
        keydown('<')

      it "outdents the current line", ->
        expect(editor.getText()).toBe "  12345\n    abcde\nABCDE"
        expect(editor.getCursorScreenPosition()).toEqual [0, 2]

    describe "when followed by a repeating <", ->
      beforeEach ->
        keydown('2')
        keydown('<')
        keydown('<')

      it "outdents multiple lines at once", ->
        expect(editor.getText()).toBe "  12345\n  abcde\nABCDE"
        expect(editor.getCursorScreenPosition()).toEqual [0, 2]

      describe "undo behavior", ->
        beforeEach -> keydown('u')

        it "indents both lines", ->
          expect(editor.getText()).toBe "    12345\n    abcde\nABCDE"

    describe "in visual mode linewise", ->
      beforeEach ->
        keydown('v', shift: true)
        keydown('j')

      describe "single outdent multiple lines", ->
        beforeEach ->
          keydown('<')

        it "outdents the current line and exits visual mode", ->
          expect(editorElement.classList.contains('normal-mode')).toBe(true)
          expect(editor.getText()).toBe "  12345\n  abcde\nABCDE"
          expect(editor.getSelectedBufferRanges()).toEqual [ [[0, 2], [0, 2]] ]

        it "allows repeating the operation", ->
          keydown('.')
          expect(editor.getText()).toBe "12345\nabcde\nABCDE"

      describe "multiple outdent multiple lines", ->
        beforeEach ->
          keydown('2')
          keydown('<')

        it "outdents both lines twice and exits visual mode", ->
          expect(editorElement.classList.contains('normal-mode')).toBe(true)
          expect(editor.getText()).toBe "12345\nabcde\nABCDE"
          expect(editor.getSelectedBufferRanges()).toEqual [ [[0, 0], [0, 0]] ]

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
        jsGrammar = atom.grammars.grammarForScopeName('source.js')
        editor.setGrammar(jsGrammar)

      afterEach ->
        editor.setGrammar(oldGrammar)

      describe "when followed by a =", ->
        beforeEach ->
          keydown('=')
          keydown('=')

        it "indents the current line", ->
          expect(editor.indentationForBufferRow(1)).toBe 0

      describe "when followed by a G", ->
        beforeEach ->
          editor.setCursorScreenPosition([0, 0])
          keydown('=')
          keydown('G', shift: true)

        it "uses the default count", ->
          expect(editor.indentationForBufferRow(1)).toBe 0
          expect(editor.indentationForBufferRow(2)).toBe 0

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
      editor.setCursorScreenPosition([0, 0])

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
      editor.setCursorBufferPosition([0, 0])
      editor.addCursorAtBufferPosition([1, 0])

    it "replaces a single character", ->
      keydown('r')
      normalModeInputKeydown('x')
      expect(editor.getText()).toBe 'x2\nx4\n\n'

    it "does nothing when cancelled", ->
      keydown('r')
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(true)
      keydown('escape')
      expect(editor.getText()).toBe '12\n34\n\n'
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "replaces a single character with a line break", ->
      keydown('r')
      atom.commands.dispatch(editor.normalModeInputView.editorElement, 'core:confirm')
      expect(editor.getText()).toBe '\n2\n\n4\n\n'
      expect(editor.getCursorBufferPositions()).toEqual [[1, 0], [3, 0]]

    it "composes properly with motions", ->
      keydown('2')
      keydown('r')
      normalModeInputKeydown('x')
      expect(editor.getText()).toBe 'xx\nxx\n\n'

    it "does nothing on an empty line", ->
      editor.setCursorBufferPosition([2, 0])
      keydown('r')
      normalModeInputKeydown('x')
      expect(editor.getText()).toBe '12\n34\n\n'

    it "does nothing if asked to replace more characters than there are on a line", ->
      keydown('3')
      keydown('r')
      normalModeInputKeydown('x')
      expect(editor.getText()).toBe '12\n34\n\n'

    describe "when in visual mode", ->
      beforeEach ->
        keydown('v')
        keydown('e')

      it "replaces the entire selection with the given character", ->
        keydown('r')
        normalModeInputKeydown('x')
        expect(editor.getText()).toBe 'xx\nxx\n\n'

      it "leaves the cursor at the beginning of the selection", ->
        keydown('r')
        normalModeInputKeydown('x')
        expect(editor.getCursorBufferPositions()).toEqual [[0, 0], [1, 0]]

    describe 'with accented characters', ->
      buildIMECompositionEvent = (event, {data, target}={}) ->
        event = new Event(event)
        event.data = data
        Object.defineProperty(event, 'target', get: -> target)
        event

      buildTextInputEvent = ({data, target}) ->
        event = new Event('textInput')
        event.data = data
        Object.defineProperty(event, 'target', get: -> target)
        event

      it 'works with IME composition', ->
        keydown('r')
        normalModeEditor = editor.normalModeInputView.editorElement
        jasmine.attachToDOM(normalModeEditor)
        domNode = normalModeEditor.component.domNode
        inputNode = domNode.querySelector('.hidden-input')
        domNode.dispatchEvent(buildIMECompositionEvent('compositionstart', target: inputNode))
        domNode.dispatchEvent(buildIMECompositionEvent('compositionupdate', data: 's', target: inputNode))
        expect(normalModeEditor.getModel().getText()).toEqual 's'
        domNode.dispatchEvent(buildIMECompositionEvent('compositionupdate', data: 'sd', target: inputNode))
        expect(normalModeEditor.getModel().getText()).toEqual 'sd'
        domNode.dispatchEvent(buildIMECompositionEvent('compositionend', target: inputNode))
        domNode.dispatchEvent(buildTextInputEvent(data: '速度', target: inputNode))
        expect(editor.getText()).toBe '速度2\n速度4\n\n'

  describe 'the m keybinding', ->
    beforeEach ->
      editor.setText('12\n34\n56\n')
      editor.setCursorBufferPosition([0, 1])

    it 'marks a position', ->
      keydown('m')
      normalModeInputKeydown('a')
      expect(vimState.getMark('a')).toEqual [0, 1]

  describe 'the ~ keybinding', ->
    beforeEach ->
      editor.setText('aBc\nXyZ')
      editor.setCursorBufferPosition([0, 0])
      editor.addCursorAtBufferPosition([1, 0])

    it 'toggles the case and moves right', ->
      keydown('~')
      expect(editor.getText()).toBe 'ABc\nxyZ'
      expect(editor.getCursorScreenPositions()).toEqual [[0, 1], [1, 1]]

      keydown('~')
      expect(editor.getText()).toBe 'Abc\nxYZ'
      expect(editor.getCursorScreenPositions()).toEqual [[0, 2], [1, 2]]

      keydown('~')
      expect(editor.getText()).toBe 'AbC\nxYz'
      expect(editor.getCursorScreenPositions()).toEqual [[0, 2], [1, 2]]

    it 'takes a count', ->
      keydown('4')
      keydown('~')

      expect(editor.getText()).toBe 'AbC\nxYz'
      expect(editor.getCursorScreenPositions()).toEqual [[0, 2], [1, 2]]

    describe "in visual mode", ->
      it "toggles the case of the selected text", ->
        editor.setCursorBufferPosition([0, 0])
        keydown("V", shift: true)
        keydown("~")
        expect(editor.getText()).toBe 'AbC\nXyZ'

    describe "with g and motion", ->
      it "toggles the case of text", ->
        editor.setCursorBufferPosition([0, 0])
        keydown("g")
        keydown("~")
        keydown("2")
        keydown("l")
        expect(editor.getText()).toBe 'Abc\nXyZ'

      it "uses default count", ->
        editor.setCursorBufferPosition([0, 0])
        keydown("g")
        keydown("~")
        keydown("G", shift: true)
        expect(editor.getText()).toBe 'AbC\nxYz'

  describe 'the U keybinding', ->
    beforeEach ->
      editor.setText('aBc\nXyZ')
      editor.setCursorBufferPosition([0, 0])

    it "makes text uppercase with g and motion", ->
      keydown("g")
      keydown("U", shift: true)
      keydown("l")
      expect(editor.getText()).toBe 'ABc\nXyZ'

      keydown("g")
      keydown("U", shift: true)
      keydown("e")
      expect(editor.getText()).toBe 'ABC\nXyZ'

      editor.setCursorBufferPosition([1, 0])
      keydown("g")
      keydown("U", shift: true)
      keydown("$")
      expect(editor.getText()).toBe 'ABC\nXYZ'
      expect(editor.getCursorScreenPosition()).toEqual [1, 2]

    it "uses default count", ->
      editor.setCursorBufferPosition([0, 0])
      keydown("g")
      keydown("U", shift: true)
      keydown("G", shift: true)
      expect(editor.getText()).toBe 'ABC\nXYZ'

    it "makes the selected text uppercase in visual mode", ->
      keydown("V", shift: true)
      keydown("U", shift: true)
      expect(editor.getText()).toBe 'ABC\nXyZ'

  describe 'the u keybinding', ->
    beforeEach ->
      editor.setText('aBc\nXyZ')
      editor.setCursorBufferPosition([0, 0])

    it "makes text lowercase with g and motion", ->
      keydown("g")
      keydown("u")
      keydown("$")
      expect(editor.getText()).toBe 'abc\nXyZ'
      expect(editor.getCursorScreenPosition()).toEqual [0, 2]

    it "uses default count", ->
      editor.setCursorBufferPosition([0, 0])
      keydown("g")
      keydown("u")
      keydown("G", shift: true)
      expect(editor.getText()).toBe 'abc\nxyz'

    it "makes the selected text lowercase in visual mode", ->
      keydown("V", shift: true)
      keydown("u")
      expect(editor.getText()).toBe 'abc\nXyZ'

  describe "the i keybinding", ->
    beforeEach ->
      editor.setText('123\n4567')
      editor.setCursorBufferPosition([0, 0])
      editor.addCursorAtBufferPosition([1, 0])

    it "allows undoing an entire batch of typing", ->
      keydown 'i'
      editor.insertText("abcXX")
      editor.backspace()
      editor.backspace()
      keydown 'escape'
      expect(editor.getText()).toBe "abc123\nabc4567"

      keydown 'i'
      editor.insertText "d"
      editor.insertText "e"
      editor.insertText "f"
      keydown 'escape'
      expect(editor.getText()).toBe "abdefc123\nabdefc4567"

      keydown 'u'
      expect(editor.getText()).toBe "abc123\nabc4567"

      keydown 'u'
      expect(editor.getText()).toBe "123\n4567"

    it "allows repeating typing", ->
      keydown 'i'
      editor.insertText("abcXX")
      editor.backspace()
      editor.backspace()
      keydown 'escape'
      expect(editor.getText()).toBe "abc123\nabc4567"

      keydown '.'
      expect(editor.getText()).toBe "ababcc123\nababcc4567"

      keydown '.'
      expect(editor.getText()).toBe "abababccc123\nabababccc4567"

    describe 'with nonlinear input', ->
      beforeEach ->
        editor.setText ''
        editor.setCursorBufferPosition [0, 0]

      it 'deals with auto-matched brackets', ->
        keydown 'i'
        # this sequence simulates what the bracket-matcher package does
        # when the user types (a)b<enter>
        editor.insertText '()'
        editor.moveLeft()
        editor.insertText 'a'
        editor.moveRight()
        editor.insertText 'b\n'
        keydown 'escape'
        expect(editor.getCursorScreenPosition()).toEqual [1,  0]

        keydown '.'
        expect(editor.getText()).toBe '(a)b\n(a)b\n'
        expect(editor.getCursorScreenPosition()).toEqual [2,  0]

      it 'deals with autocomplete', ->
        keydown 'i'
        # this sequence simulates autocompletion of 'add' to 'addFoo'
        editor.insertText 'a'
        editor.insertText 'd'
        editor.insertText 'd'
        editor.setTextInBufferRange [[0, 0], [0, 3]], 'addFoo'
        keydown 'escape'
        expect(editor.getCursorScreenPosition()).toEqual [0,  5]
        expect(editor.getText()).toBe 'addFoo'

        keydown '.'
        expect(editor.getText()).toBe 'addFoaddFooo'
        expect(editor.getCursorScreenPosition()).toEqual [0,  10]

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
      expect(editor.getCursorScreenPosition()).toEqual [0, 2]
      keydown '.'
      expect(editor.getText()).toBe "abcabc"
      expect(editor.getCursorScreenPosition()).toEqual [0, 5]

  describe "the ctrl-a/ctrl-x keybindings", ->
    beforeEach ->
      atom.config.set 'vim-mode.numberRegex', settings.config.numberRegex.default
      editor.setText('123\nab45\ncd-67ef\nab-5\na-bcdef')
      editor.setCursorBufferPosition [0, 0]
      editor.addCursorAtBufferPosition [1, 0]
      editor.addCursorAtBufferPosition [2, 0]
      editor.addCursorAtBufferPosition [3, 3]
      editor.addCursorAtBufferPosition [4, 0]

    describe "increasing numbers", ->
      it "increases the next number", ->
        keydown('a', ctrl: true)
        expect(editor.getCursorBufferPositions()).toEqual [[0, 2], [1, 3], [2, 4], [3, 3], [4, 0]]
        expect(editor.getText()).toBe '124\nab46\ncd-66ef\nab-4\na-bcdef'
        expect(atom.beep).not.toHaveBeenCalled()

      it "repeats with .", ->
        keydown 'a', ctrl: true
        keydown '.'
        expect(editor.getCursorBufferPositions()).toEqual [[0, 2], [1, 3], [2, 4], [3, 3], [4, 0]]
        expect(editor.getText()).toBe '125\nab47\ncd-65ef\nab-3\na-bcdef'
        expect(atom.beep).not.toHaveBeenCalled()

      it "can have a count", ->
        keydown '5'
        keydown 'a', ctrl: true
        expect(editor.getCursorBufferPositions()).toEqual [[0, 2], [1, 3], [2, 4], [3, 2], [4, 0]]
        expect(editor.getText()).toBe '128\nab50\ncd-62ef\nab0\na-bcdef'
        expect(atom.beep).not.toHaveBeenCalled()

      it "can make a negative number positive, change number of digits", ->
        keydown '9'
        keydown '9'
        keydown 'a', ctrl: true
        expect(editor.getCursorBufferPositions()).toEqual [[0, 2], [1, 4], [2, 3], [3, 3], [4, 0]]
        expect(editor.getText()).toBe '222\nab144\ncd32ef\nab94\na-bcdef'
        expect(atom.beep).not.toHaveBeenCalled()

      it "does nothing when cursor is after the number", ->
        editor.setCursorBufferPosition [2, 5]
        keydown 'a', ctrl: true
        expect(editor.getCursorBufferPositions()).toEqual [[2, 5]]
        expect(editor.getText()).toBe '123\nab45\ncd-67ef\nab-5\na-bcdef'
        expect(atom.beep).toHaveBeenCalled()

      it "does nothing on an empty line", ->
        editor.setText('\n')
        editor.setCursorBufferPosition [0, 0]
        editor.addCursorAtBufferPosition [1, 0]
        keydown 'a', ctrl: true
        expect(editor.getCursorBufferPositions()).toEqual [[0, 0], [1, 0]]
        expect(editor.getText()).toBe '\n'
        expect(atom.beep).toHaveBeenCalled()

      it "honours the vim-mode:numberRegex setting", ->
        editor.setText('123\nab45\ncd -67ef\nab-5\na-bcdef')
        editor.setCursorBufferPosition [0, 0]
        editor.addCursorAtBufferPosition [1, 0]
        editor.addCursorAtBufferPosition [2, 0]
        editor.addCursorAtBufferPosition [3, 3]
        editor.addCursorAtBufferPosition [4, 0]
        atom.config.set('vim-mode.numberRegex', '(?:\\B-)?[0-9]+')
        keydown('a', ctrl: true)
        expect(editor.getCursorBufferPositions()).toEqual [[0, 2], [1, 3], [2, 5], [3, 3], [4, 0]]
        expect(editor.getText()).toBe '124\nab46\ncd -66ef\nab-6\na-bcdef'
        expect(atom.beep).not.toHaveBeenCalled()

    describe "decreasing numbers", ->
      it "decreases the next number", ->
        keydown('x', ctrl: true)
        expect(editor.getCursorBufferPositions()).toEqual [[0, 2], [1, 3], [2, 4], [3, 3], [4, 0]]
        expect(editor.getText()).toBe '122\nab44\ncd-68ef\nab-6\na-bcdef'
        expect(atom.beep).not.toHaveBeenCalled()

      it "repeats with .", ->
        keydown 'x', ctrl: true
        keydown '.'
        expect(editor.getCursorBufferPositions()).toEqual [[0, 2], [1, 3], [2, 4], [3, 3], [4, 0]]
        expect(editor.getText()).toBe '121\nab43\ncd-69ef\nab-7\na-bcdef'
        expect(atom.beep).not.toHaveBeenCalled()

      it "can have a count", ->
        keydown '5'
        keydown 'x', ctrl: true
        expect(editor.getCursorBufferPositions()).toEqual [[0, 2], [1, 3], [2, 4], [3, 4], [4, 0]]
        expect(editor.getText()).toBe '118\nab40\ncd-72ef\nab-10\na-bcdef'
        expect(atom.beep).not.toHaveBeenCalled()

      it "can make a positive number negative, change number of digits", ->
        keydown '9'
        keydown '9'
        keydown 'x', ctrl: true
        expect(editor.getCursorBufferPositions()).toEqual [[0, 1], [1, 4], [2, 5], [3, 5], [4, 0]]
        expect(editor.getText()).toBe '24\nab-54\ncd-166ef\nab-104\na-bcdef'
        expect(atom.beep).not.toHaveBeenCalled()

      it "does nothing when cursor is after the number", ->
        editor.setCursorBufferPosition [2, 5]
        keydown 'x', ctrl: true
        expect(editor.getCursorBufferPositions()).toEqual [[2, 5]]
        expect(editor.getText()).toBe '123\nab45\ncd-67ef\nab-5\na-bcdef'
        expect(atom.beep).toHaveBeenCalled()

      it "does nothing on an empty line", ->
        editor.setText('\n')
        editor.setCursorBufferPosition [0, 0]
        editor.addCursorAtBufferPosition [1, 0]
        keydown 'x', ctrl: true
        expect(editor.getCursorBufferPositions()).toEqual [[0, 0], [1, 0]]
        expect(editor.getText()).toBe '\n'
        expect(atom.beep).toHaveBeenCalled()

      it "honours the vim-mode:numberRegex setting", ->
        editor.setText('123\nab45\ncd -67ef\nab-5\na-bcdef')
        editor.setCursorBufferPosition [0, 0]
        editor.addCursorAtBufferPosition [1, 0]
        editor.addCursorAtBufferPosition [2, 0]
        editor.addCursorAtBufferPosition [3, 3]
        editor.addCursorAtBufferPosition [4, 0]
        atom.config.set('vim-mode.numberRegex', '(?:\\B-)?[0-9]+')
        keydown('x', ctrl: true)
        expect(editor.getCursorBufferPositions()).toEqual [[0, 2], [1, 3], [2, 5], [3, 3], [4, 0]]
        expect(editor.getText()).toBe '122\nab44\ncd -68ef\nab-4\na-bcdef'
        expect(atom.beep).not.toHaveBeenCalled()

  describe 'the R keybinding', ->
    beforeEach ->
      editor.setText('12345\n67890')
      editor.setCursorBufferPosition([0, 2])

    it "enters replace mode and replaces characters", ->
      keydown "R", shift: true
      expect(editorElement.classList.contains('insert-mode')).toBe true
      expect(editorElement.classList.contains('replace-mode')).toBe true

      editor.insertText "ab"
      keydown 'escape'

      expect(editor.getText()).toBe "12ab5\n67890"
      expect(editor.getCursorScreenPosition()).toEqual [0, 3]
      expect(editorElement.classList.contains('insert-mode')).toBe false
      expect(editorElement.classList.contains('replace-mode')).toBe false
      expect(editorElement.classList.contains('normal-mode')).toBe true

    it "continues beyond end of line as insert", ->
      keydown "R", shift: true
      expect(editorElement.classList.contains('insert-mode')).toBe true
      expect(editorElement.classList.contains('replace-mode')).toBe true

      editor.insertText "abcde"
      keydown 'escape'

      expect(editor.getText()).toBe "12abcde\n67890"

    it "treats backspace as undo", ->
      editor.insertText "foo"
      keydown "R", shift: true

      editor.insertText "a"
      editor.insertText "b"
      expect(editor.getText()).toBe "12fooab5\n67890"

      keydown 'backspace', raw: true
      expect(editor.getText()).toBe "12fooa45\n67890"

      editor.insertText "c"

      expect(editor.getText()).toBe "12fooac5\n67890"

      keydown 'backspace', raw: true
      keydown 'backspace', raw: true

      expect(editor.getText()).toBe "12foo345\n67890"
      expect(editor.getSelectedText()).toBe ""

      keydown 'backspace', raw: true
      expect(editor.getText()).toBe "12foo345\n67890"
      expect(editor.getSelectedText()).toBe ""

    it "can be repeated", ->
      keydown "R", shift: true
      editor.insertText "ab"
      keydown 'escape'
      editor.setCursorBufferPosition([1, 2])
      keydown '.'
      expect(editor.getText()).toBe "12ab5\n67ab0"
      expect(editor.getCursorScreenPosition()).toEqual [1, 3]

      editor.setCursorBufferPosition([0, 4])
      keydown '.'
      expect(editor.getText()).toBe "12abab\n67ab0"
      expect(editor.getCursorScreenPosition()).toEqual [0, 5]

    it "can be interrupted by arrow keys and behave as insert for repeat", ->
      # FIXME don't know how to test this (also, depends on PR #568)

    it "repeats correctly when backspace was used in the text", ->
      keydown "R", shift: true
      editor.insertText "a"
      keydown 'backspace', raw: true
      editor.insertText "b"
      keydown 'escape'
      editor.setCursorBufferPosition([1, 2])
      keydown '.'
      expect(editor.getText()).toBe "12b45\n67b90"
      expect(editor.getCursorScreenPosition()).toEqual [1, 2]

      editor.setCursorBufferPosition([0, 4])
      keydown '.'
      expect(editor.getText()).toBe "12b4b\n67b90"
      expect(editor.getCursorScreenPosition()).toEqual [0, 4]

    it "doesn't replace a character if newline is entered", ->
      keydown "R", shift: true
      expect(editorElement.classList.contains('insert-mode')).toBe true
      expect(editorElement.classList.contains('replace-mode')).toBe true

      editor.insertText "\n"
      keydown 'escape'

      expect(editor.getText()).toBe "12\n345\n67890"
