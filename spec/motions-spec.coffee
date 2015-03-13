helpers = require './spec-helper'

describe "Motions", ->
  [editor, editorElement, vimState] = []

  beforeEach ->
    vimMode = atom.packages.loadPackage('vim-mode')
    vimMode.activateResources()

    helpers.getEditorElement (element) ->
      editorElement = element
      editor = editorElement.getModel()
      vimState = editorElement.vimState
      vimState.activateCommandMode()
      vimState.resetCommandMode()

  keydown = (key, options={}) ->
    options.element ?= editorElement
    helpers.keydown(key, options)

  commandModeInputKeydown = (key, opts = {}) ->
    opts.element = editor.commandModeInputView.editor.find('input').get(0)
    opts.raw = true
    keydown(key, opts)

  describe "simple motions", ->
    beforeEach ->
      editor.setText("12345\nabcd\nABCDE")
      editor.setCursorScreenPosition([1, 1])

    describe "the h keybinding", ->
      describe "as a motion", ->
        it "moves the cursor left, but not to the previous line", ->
          keydown('h')
          expect(editor.getCursorScreenPosition()).toEqual [1, 0]

          keydown('h')
          expect(editor.getCursorScreenPosition()).toEqual [1, 0]

        it "moves the cursor to the previous line if wrapLeftRightMotion is true", ->
          atom.config.set('vim-mode.wrapLeftRightMotion', true)
          keydown('h')
          keydown('h')
          expect(editor.getCursorScreenPosition()).toEqual [0, 4]

      describe "as a selection", ->
        it "selects the character to the left", ->
          keydown('y')
          keydown('h')

          expect(vimState.getRegister('"').text).toBe 'a'
          expect(editor.getCursorScreenPosition()).toEqual [1, 0]

    describe "the j keybinding", ->
      it "moves the cursor down, but not to the end of the last line", ->
        keydown('j')
        expect(editor.getCursorScreenPosition()).toEqual [2, 1]

        keydown('j')
        expect(editor.getCursorScreenPosition()).toEqual [2, 1]

      it "moves the cursor to the end of the line, not past it", ->
        editor.setCursorScreenPosition([0,4])

        keydown('j')
        expect(editor.getCursorScreenPosition()).toEqual [1, 3]

      it "remembers the position it column it was in after moving to shorter line", ->
        editor.setCursorScreenPosition([0,4])

        keydown('j')
        expect(editor.getCursorScreenPosition()).toEqual [1, 3]

        keydown('j')
        expect(editor.getCursorScreenPosition()).toEqual [2, 4]

      describe "when visual mode", ->
        beforeEach ->
          keydown('v')
          expect(editor.getCursorScreenPosition()).toEqual [1, 2]

        it "moves the cursor down", ->
          keydown('j')
          expect(editor.getCursorScreenPosition()).toEqual [2, 2]

        it "doesn't go over after the last line", ->
          keydown('j')
          expect(editor.getCursorScreenPosition()).toEqual [2, 2]

        it "selects the text while moving", ->
          keydown('j')
          expect(editor.getSelectedText()).toBe "bcd\nAB"

    describe "the k keybinding", ->
      it "moves the cursor up, but not to the beginning of the first line", ->
        keydown('k')
        expect(editor.getCursorScreenPosition()).toEqual [0, 1]

        keydown('k')
        expect(editor.getCursorScreenPosition()).toEqual [0, 1]

    describe "the l keybinding", ->
      beforeEach -> editor.setCursorScreenPosition([1, 2])

      it "moves the cursor right, but not to the next line", ->
        keydown('l')
        expect(editor.getCursorScreenPosition()).toEqual [1, 3]

        keydown('l')
        expect(editor.getCursorScreenPosition()).toEqual [1, 3]

      it "moves the cursor to the next line if wrapLeftRightMotion is true", ->
        atom.config.set('vim-mode.wrapLeftRightMotion', true)
        keydown('l')
        keydown('l')
        expect(editor.getCursorScreenPosition()).toEqual [2, 0]

      describe "on a blank line", ->
        it "doesn't move the cursor", ->
          editor.setText("\n\n\n")
          editor.setCursorBufferPosition([1, 0])
          keydown('l')
          expect(editor.getCursorBufferPosition()).toEqual [1, 0]

  describe "the w keybinding", ->
    beforeEach -> editor.setText("ab cde1+- \n xyz\n\nzip")

    describe "as a motion", ->
      beforeEach -> editor.setCursorScreenPosition([0, 0])

      it "moves the cursor to the beginning of the next word", ->
        keydown('w')
        expect(editor.getCursorScreenPosition()).toEqual [0, 3]

        keydown('w')
        expect(editor.getCursorScreenPosition()).toEqual [0, 7]

        keydown('w')
        expect(editor.getCursorScreenPosition()).toEqual [1, 1]

        keydown('w')
        expect(editor.getCursorScreenPosition()).toEqual [2, 0]

        # FIXME: The definition of Cursor#getEndOfCurrentWordBufferPosition,
        # means that the end of the word can't be the current cursor
        # position (even though it is when your cursor is on a new line).
        #
        # Therefore it picks the end of the next word here (which is [3,3])
        # to start looking for the next word, which is also the end of the
        # buffer so the cursor never advances.
        #
        # See atom/vim-mode#3
        keydown('w')
        expect(editor.getCursorScreenPosition()).toEqual [3, 0]

        keydown('w')
        expect(editor.getCursorScreenPosition()).toEqual [3, 3]

        # After cursor gets to the EOF, it should stay there.
        keydown('w')
        expect(editor.getCursorScreenPosition()).toEqual [3, 3]

      it "moves the cursor to the end of the word if last word in file", ->
        editor.setText("abc")
        editor.setCursorScreenPosition([0, 0])
        keydown('w')
        expect(editor.getCursorScreenPosition()).toEqual([0, 3])

    describe "as a selection", ->
      describe "within a word", ->
        beforeEach ->
          editor.setCursorScreenPosition([0, 0])
          keydown('y')
          keydown('w')

        it "selects to the end of the word", ->
          expect(vimState.getRegister('"').text).toBe 'ab '

      describe "between words", ->
        beforeEach ->
          editor.setCursorScreenPosition([0, 2])
          keydown('y')
          keydown('w')

        it "selects the whitespace", ->
          expect(vimState.getRegister('"').text).toBe ' '

  describe "the W keybinding", ->
    beforeEach -> editor.setText("cde1+- ab \n xyz\n\nzip")

    describe "as a motion", ->
      beforeEach -> editor.setCursorScreenPosition([0, 0])

      it "moves the cursor to the beginning of the next word", ->
        keydown('W', shift:true)
        expect(editor.getCursorScreenPosition()).toEqual [0, 7]

        keydown('W', shift:true)
        expect(editor.getCursorScreenPosition()).toEqual [1, 1]

        keydown('W', shift:true)
        expect(editor.getCursorScreenPosition()).toEqual [2, 0]

        keydown('W', shift:true)
        expect(editor.getCursorScreenPosition()).toEqual [3, 0]

    describe "as a selection", ->
      describe "within a word", ->
        it "selects to the end of the whole word", ->
          editor.setCursorScreenPosition([0, 0])
          keydown('y')
          keydown('W', shift:true)
          expect(vimState.getRegister('"').text).toBe 'cde1+- '

      it "continues past blank lines", ->
        editor.setCursorScreenPosition([2, 0])

        keydown('d')
        keydown('W', shift:true)
        expect(editor.getText()).toBe "cde1+- ab \n xyz\nzip"
        expect(vimState.getRegister('"').text).toBe '\n'

      it "doesn't go past the end of the file", ->
        editor.setCursorScreenPosition([3, 0])

        keydown('d')
        keydown('W', shift:true)
        expect(editor.getText()).toBe "cde1+- ab \n xyz\n\n"
        expect(vimState.getRegister('"').text).toBe 'zip'

  describe "the e keybinding", ->
    beforeEach -> editor.setText("ab cde1+- \n xyz\n\nzip")

    describe "as a motion", ->
      beforeEach -> editor.setCursorScreenPosition([0, 0])

      it "moves the cursor to the end of the current word", ->
        keydown('e')
        expect(editor.getCursorScreenPosition()).toEqual [0, 1]

        keydown('e')
        expect(editor.getCursorScreenPosition()).toEqual [0, 6]

        keydown('e')
        expect(editor.getCursorScreenPosition()).toEqual [0, 8]

        keydown('e')
        expect(editor.getCursorScreenPosition()).toEqual [1, 3]

        keydown('e')
        expect(editor.getCursorScreenPosition()).toEqual [3, 2]

    describe "as selection", ->
      describe "within a word", ->
        beforeEach ->
          editor.setCursorScreenPosition([0, 0])
          keydown('y')
          keydown('e')

        it "selects to the end of the current word", ->
          expect(vimState.getRegister('"').text).toBe 'ab'

      describe "between words", ->
        beforeEach ->
          editor.setCursorScreenPosition([0, 2])
          keydown('y')
          keydown('e')

        it "selects to the end of the next word", ->
          expect(vimState.getRegister('"').text).toBe ' cde1'

  describe "the E keybinding", ->
    beforeEach -> editor.setText("ab  cde1+- \n xyz \n\nzip\n")

    describe "as a motion", ->
      beforeEach -> editor.setCursorScreenPosition([0, 0])

      it "moves the cursor to the end of the current word", ->
        keydown('E', shift: true)
        expect(editor.getCursorScreenPosition()).toEqual [0, 1]

        keydown('E', shift: true)
        expect(editor.getCursorScreenPosition()).toEqual [0, 9]

        keydown('E', shift: true)
        expect(editor.getCursorScreenPosition()).toEqual [1, 3]

        keydown('E', shift: true)
        expect(editor.getCursorScreenPosition()).toEqual [3, 2]

        keydown('E', shift: true)
        expect(editor.getCursorScreenPosition()).toEqual [4, 0]

    describe "as selection", ->
      describe "within a word", ->
        beforeEach ->
          editor.setCursorScreenPosition([0, 0])
          keydown('y')
          keydown('E', shift: true)

        it "selects to the end of the current word", ->
          expect(vimState.getRegister('"').text).toBe 'ab'

      describe "between words", ->
        beforeEach ->
          editor.setCursorScreenPosition([0, 2])
          keydown('y')
          keydown('E', shift: true)

        it "selects to the end of the next word", ->
          expect(vimState.getRegister('"').text).toBe '  cde1+-'

      describe "press more than once", ->
        beforeEach ->
          editor.setCursorScreenPosition([0, 0])
          keydown('v')
          keydown('E', shift: true)
          keydown('E', shift: true)
          keydown('y')

        it "selects to the end of the current word", ->
          expect(vimState.getRegister('"').text).toBe 'ab  cde1+-'

  describe "the } keybinding", ->
    beforeEach ->
      editor.setText("abcde\n\nfghij\nhijk\n  xyz  \n\nzip\n\n  \nthe end")
      editor.setCursorScreenPosition([0, 0])

    describe "as a motion", ->
      it "moves the cursor to the end of the paragraph", ->
        keydown('}')
        expect(editor.getCursorScreenPosition()).toEqual [1, 0]

        keydown('}')
        expect(editor.getCursorScreenPosition()).toEqual [5, 0]

        keydown('}')
        expect(editor.getCursorScreenPosition()).toEqual [7, 0]

        keydown('}')
        expect(editor.getCursorScreenPosition()).toEqual [9, 6]

    describe "as a selection", ->
      beforeEach ->
        keydown('y')
        keydown('}')

      it 'selects to the end of the current paragraph', ->
        expect(vimState.getRegister('"').text).toBe "abcde\n"

  describe "the { keybinding", ->
    beforeEach ->
      editor.setText("abcde\n\nfghij\nhijk\n  xyz  \n\nzip\n\n  \nthe end")
      editor.setCursorScreenPosition([9, 0])

    describe "as a motion", ->
      it "moves the cursor to the beginning of the paragraph", ->
        keydown('{')
        expect(editor.getCursorScreenPosition()).toEqual [7, 0]

        keydown('{')
        expect(editor.getCursorScreenPosition()).toEqual [5, 0]

        keydown('{')
        expect(editor.getCursorScreenPosition()).toEqual [1, 0]

        keydown('{')
        expect(editor.getCursorScreenPosition()).toEqual [0, 0]

    describe "as a selection", ->
      beforeEach ->
        editor.setCursorScreenPosition([7, 0])
        keydown('y')
        keydown('{')

      it 'selects to the beginning of the current paragraph', ->
        expect(vimState.getRegister('"').text).toBe "\nzip\n"

  describe "the b keybinding", ->
    beforeEach -> editor.setText(" ab cde1+- \n xyz\n\nzip }\n last")

    describe "as a motion", ->
      beforeEach -> editor.setCursorScreenPosition([4,1])

      it "moves the cursor to the beginning of the previous word", ->
        keydown('b')
        expect(editor.getCursorScreenPosition()).toEqual [3, 4]

        keydown('b')
        expect(editor.getCursorScreenPosition()).toEqual [3, 0]

        keydown('b')
        expect(editor.getCursorScreenPosition()).toEqual [2, 0]

        keydown('b')
        expect(editor.getCursorScreenPosition()).toEqual [1, 1]

        keydown('b')
        expect(editor.getCursorScreenPosition()).toEqual [0, 8]

        keydown('b')
        expect(editor.getCursorScreenPosition()).toEqual [0, 4]

        keydown('b')
        expect(editor.getCursorScreenPosition()).toEqual [0, 1]

        # Go to start of the file, after moving past the first word
        keydown('b')
        expect(editor.getCursorScreenPosition()).toEqual [0, 0]

        # Stay at the start of the file
        keydown('b')
        expect(editor.getCursorScreenPosition()).toEqual [0, 0]

    describe "as a selection", ->
      describe "within a word", ->
        beforeEach ->
          editor.setCursorScreenPosition([0, 2])
          keydown('y')
          keydown('b')

        it "selects to the beginning of the current word", ->
          expect(vimState.getRegister('"').text).toBe 'a'
          expect(editor.getCursorScreenPosition()).toEqual [0, 1]

      describe "between words", ->
        beforeEach ->
          editor.setCursorScreenPosition([0, 4])
          keydown('y')
          keydown('b')

        it "selects to the beginning of the last word", ->
          expect(vimState.getRegister('"').text).toBe 'ab '
          expect(editor.getCursorScreenPosition()).toEqual [0, 1]

  describe "the B keybinding", ->
    beforeEach -> editor.setText("cde1+- ab \n\t xyz-123\n\n zip")

    describe "as a motion", ->
      beforeEach -> editor.setCursorScreenPosition([4, 1])

      it "moves the cursor to the beginning of the previous word", ->
        keydown('B', shift:true)
        expect(editor.getCursorScreenPosition()).toEqual [3, 1]

        keydown('B', shift:true)
        expect(editor.getCursorScreenPosition()).toEqual [2, 0]

        keydown('B', shift:true)
        expect(editor.getCursorScreenPosition()).toEqual [1, 3]

        keydown('B', shift:true)
        expect(editor.getCursorScreenPosition()).toEqual [0, 7]

        keydown('B', shift:true)
        expect(editor.getCursorScreenPosition()).toEqual [0, 0]

    describe "as a selection", ->
      it "selects to the beginning of the whole word", ->
        editor.setCursorScreenPosition([1, 10])
        keydown('y')
        keydown('B', shift:true)
        expect(vimState.getRegister('"').text).toBe 'xyz-123'

      it "doesn't go past the beginning of the file", ->
        editor.setCursorScreenPosition([0, 0])
        keydown('y')
        keydown('B', shift:true)
        expect(vimState.getRegister('"').text).toBe ''

  describe "the ^ keybinding", ->
    beforeEach ->
      editor.setText("  abcde")

    describe "from the beginning of the line", ->
      beforeEach -> editor.setCursorScreenPosition([0, 0])

      describe "as a motion", ->
        beforeEach -> keydown('^')

        it "moves the cursor to the first character of the line", ->
          expect(editor.getCursorScreenPosition()).toEqual [0, 2]

      describe "as a selection", ->
        beforeEach ->
          keydown('d')
          keydown('^')

        it 'selects to the first character of the line', ->
          expect(editor.getText()).toBe 'abcde'
          expect(editor.getCursorScreenPosition()).toEqual [0, 0]

    describe "from the first character of the line", ->
      beforeEach -> editor.setCursorScreenPosition([0, 2])

      describe "as a motion", ->
        beforeEach -> keydown('^')

        it "stays put", ->
          expect(editor.getCursorScreenPosition()).toEqual [0, 2]

      describe "as a selection", ->
        beforeEach ->
          keydown('d')
          keydown('^')

        it "does nothing", ->
          expect(editor.getText()).toBe '  abcde'
          expect(editor.getCursorScreenPosition()).toEqual [0, 2]

    describe "from the middle of a word", ->
      beforeEach -> editor.setCursorScreenPosition([0, 4])

      describe "as a motion", ->
        beforeEach -> keydown('^')

        it "moves the cursor to the first character of the line", ->
          expect(editor.getCursorScreenPosition()).toEqual [0, 2]

      describe "as a selection", ->
        beforeEach ->
          keydown('d')
          keydown('^')

        it 'selects to the first character of the line', ->
          expect(editor.getText()).toBe '  cde'
          expect(editor.getCursorScreenPosition()).toEqual [0, 2]

  describe "the 0 keybinding", ->
    beforeEach ->
      editor.setText("  abcde")
      editor.setCursorScreenPosition([0, 4])

    describe "as a motion", ->
      beforeEach -> keydown('0')

      it "moves the cursor to the first column", ->
        expect(editor.getCursorScreenPosition()).toEqual [0, 0]

    describe "as a selection", ->
      beforeEach ->
        keydown('d')
        keydown('0')

      it 'selects to the first column of the line', ->
        expect(editor.getText()).toBe 'cde'
        expect(editor.getCursorScreenPosition()).toEqual [0, 0]

  describe "the $ keybinding", ->
    beforeEach ->
      editor.setText("  abcde\n\n1234567890")
      editor.setCursorScreenPosition([0, 4])

    describe "as a motion from empty line", ->
      beforeEach -> editor.setCursorScreenPosition([1, 0])

      it "moves the cursor to the end of the line", ->
        expect(editor.getCursorScreenPosition()).toEqual [1, 0]

    describe "as a motion", ->
      beforeEach -> keydown('$')

      # FIXME: See atom/vim-mode#2
      it "moves the cursor to the end of the line", ->
        expect(editor.getCursorScreenPosition()).toEqual [0, 6]

      it "should remain in the last column when moving down", ->
        keydown('j')
        expect(editor.getCursorScreenPosition()).toEqual [1, 0]

        keydown('j')
        expect(editor.getCursorScreenPosition()).toEqual [2, 9]

    describe "as a selection", ->
      beforeEach ->
        keydown('d')
        keydown('$')

      it "selects to the beginning of the lines", ->
        expect(editor.getText()).toBe "  ab\n\n1234567890"
        expect(editor.getCursorScreenPosition()).toEqual [0, 3]

  describe "the 0 keybinding", ->
    beforeEach ->
      editor.setText("  a\n")
      editor.setCursorScreenPosition([0, 2])

    describe "as a motion", ->
      beforeEach -> keydown('0')

      it "moves the cursor to the beginning of the line", ->
        expect(editor.getCursorScreenPosition()).toEqual [0,0]

  describe "the - keybinding", ->
    beforeEach ->
      editor.setText("abcdefg\n  abc\n  abc\n")

    describe "from the middle of a line", ->
      beforeEach -> editor.setCursorScreenPosition([1, 3])

      describe "as a motion", ->
        beforeEach -> keydown('-')

        it "moves the cursor to the first character of the previous line", ->
          expect(editor.getCursorScreenPosition()).toEqual [0, 0]

      describe "as a selection", ->
        beforeEach ->
          keydown('d')
          keydown('-')

        it "deletes the current and previous line", ->
          expect(editor.getText()).toBe "  abc\n"
          # commented out because the column is wrong due to a bug in `k`; re-enable when `k` is fixed
          #expect(editor.getCursorScreenPosition()).toEqual [0, 3]

    describe "from the first character of a line indented the same as the previous one", ->
      beforeEach -> editor.setCursorScreenPosition([2, 2])

      describe "as a motion", ->
        beforeEach -> keydown('-')

        it "moves to the first character of the previous line (directly above)", ->
          expect(editor.getCursorScreenPosition()).toEqual [1, 2]

      describe "as a selection", ->
        beforeEach ->
          keydown('d')
          keydown('-')

        it "selects to the first character of the previous line (directly above)", ->
          expect(editor.getText()).toBe "abcdefg\n"
          # commented out because the column is wrong due to a bug in `k`; re-enable when `k` is fixed
          #expect(editor.getCursorScreenPosition()).toEqual [0, 2]

    describe "from the beginning of a line preceded by an indented line", ->
      beforeEach -> editor.setCursorScreenPosition([2, 0])

      describe "as a motion", ->
        beforeEach -> keydown('-')

        it "moves the cursor to the first character of the previous line", ->
          expect(editor.getCursorScreenPosition()).toEqual [1, 2]

      describe "as a selection", ->
        beforeEach ->
          keydown('d')
          keydown('-')

        it "selects to the first character of the previous line", ->
          expect(editor.getText()).toBe "abcdefg\n"
          # commented out because the column is wrong due to a bug in `k`; re-enable when `k` is fixed
          #expect(editor.getCursorScreenPosition()).toEqual [0, 0]

    describe "with a count", ->
      beforeEach ->
        editor.setText("1\n2\n3\n4\n5\n6\n")
        editor.setCursorScreenPosition([4, 0])

      describe "as a motion", ->
        beforeEach ->
          keydown('3')
          keydown('-')

        it "moves the cursor to the first character of that many lines previous", ->
          expect(editor.getCursorScreenPosition()).toEqual [1, 0]

      describe "as a selection", ->
        beforeEach ->
          keydown('d')
          keydown('3')
          keydown('-')

        it "deletes the current line plus that many previous lines", ->
          expect(editor.getText()).toBe "1\n6\n"
          # commented out because the column is wrong due to a bug in `k`; re-enable when `k` is fixed
          #expect(editor.getCursorScreenPosition()).toEqual [1, 0]

  describe "the + keybinding", ->
    beforeEach ->
      editor.setText("  abc\n  abc\nabcdefg\n")

    describe "from the middle of a line", ->
      beforeEach -> editor.setCursorScreenPosition([1, 3])

      describe "as a motion", ->
        beforeEach -> keydown('+')

        it "moves the cursor to the first character of the next line", ->
          expect(editor.getCursorScreenPosition()).toEqual [2, 0]

      describe "as a selection", ->
        beforeEach ->
          keydown('d')
          keydown('+')

        it "deletes the current and next line", ->
          expect(editor.getText()).toBe "  abc\n"
          # commented out because the column is wrong due to a bug in `j`; re-enable when `j` is fixed
          #expect(editor.getCursorScreenPosition()).toEqual [0, 3]

    describe "from the first character of a line indented the same as the next one", ->
      beforeEach -> editor.setCursorScreenPosition([0, 2])

      describe "as a motion", ->
        beforeEach -> keydown('+')

        it "moves to the first character of the next line (directly below)", ->
          expect(editor.getCursorScreenPosition()).toEqual [1, 2]

      describe "as a selection", ->
        beforeEach ->
          keydown('d')
          keydown('+')

        it "selects to the first character of the next line (directly below)", ->
          expect(editor.getText()).toBe "abcdefg\n"
          # commented out because the column is wrong due to a bug in `j`; re-enable when `j` is fixed
          #expect(editor.getCursorScreenPosition()).toEqual [0, 2]

    describe "from the beginning of a line followed by an indented line", ->
      beforeEach -> editor.setCursorScreenPosition([0, 0])

      describe "as a motion", ->
        beforeEach -> keydown('+')

        it "moves the cursor to the first character of the next line", ->
          expect(editor.getCursorScreenPosition()).toEqual [1, 2]

      describe "as a selection", ->
        beforeEach ->
          keydown('d')
          keydown('+')

        it "selects to the first character of the next line", ->
          expect(editor.getText()).toBe "abcdefg\n"
          # commented out because the column is wrong due to a bug in `j`; re-enable when `j` is fixed
          #expect(editor.getCursorScreenPosition()).toEqual [0, 0]

    describe "with a count", ->
      beforeEach ->
        editor.setText("1\n2\n3\n4\n5\n6\n")
        editor.setCursorScreenPosition([1, 0])

      describe "as a motion", ->
        beforeEach ->
          keydown('3')
          keydown('+')

        it "moves the cursor to the first character of that many lines following", ->
          expect(editor.getCursorScreenPosition()).toEqual [4, 0]

      describe "as a selection", ->
        beforeEach ->
          keydown('d')
          keydown('3')
          keydown('+')

        it "deletes the current line plus that many following lines", ->
          expect(editor.getText()).toBe "1\n6\n"
          # commented out because the column is wrong due to a bug in `j`; re-enable when `j` is fixed
          #expect(editor.getCursorScreenPosition()).toEqual [1, 0]

  describe "the _ keybinding", ->
    beforeEach ->
      editor.setText("  abc\n  abc\nabcdefg\n")

    describe "from the middle of a line", ->
      beforeEach -> editor.setCursorScreenPosition([1, 3])

      describe "as a motion", ->
        beforeEach -> keydown('_')

        it "moves the cursor to the first character of the current line", ->
          expect(editor.getCursorScreenPosition()).toEqual [1, 2]

      describe "as a selection", ->
        beforeEach ->
          keydown('d')
          keydown('_')

        it "deletes the current line", ->
          expect(editor.getText()).toBe "  abc\nabcdefg\n"
          expect(editor.getCursorScreenPosition()).toEqual [1, 0]

    describe "with a count", ->
      beforeEach ->
        editor.setText("1\n2\n3\n4\n5\n6\n")
        editor.setCursorScreenPosition([1, 0])

      describe "as a motion", ->
        beforeEach ->
          keydown('3')
          keydown('_')

        it "moves the cursor to the first character of that many lines following", ->
          expect(editor.getCursorScreenPosition()).toEqual [3, 0]

      describe "as a selection", ->
        beforeEach ->
          keydown('d')
          keydown('3')
          keydown('_')

        it "deletes the current line plus that many following lines", ->
          expect(editor.getText()).toBe "1\n5\n6\n"
          expect(editor.getCursorScreenPosition()).toEqual [1, 0]

  describe "the enter keybinding", ->
    keydownCodeForEnter = '\r' # 'enter' does not work
    startingText = "  abc\n  abc\nabcdefg\n"

    describe "from the middle of a line", ->
      startingCursorPosition = [1, 3]

      describe "as a motion", ->
        it "acts the same as the + keybinding", ->
          # do it with + and save the results
          editor.setText(startingText)
          editor.setCursorScreenPosition(startingCursorPosition)
          keydown('+')
          referenceCursorPosition = editor.getCursorScreenPosition()
          # do it again with enter and compare the results
          editor.setText(startingText)
          editor.setCursorScreenPosition(startingCursorPosition)
          keydown(keydownCodeForEnter)
          expect(editor.getCursorScreenPosition()).toEqual referenceCursorPosition

      describe "as a selection", ->
        it "acts the same as the + keybinding", ->
          # do it with + and save the results
          editor.setText(startingText)
          editor.setCursorScreenPosition(startingCursorPosition)
          keydown('d')
          keydown('+')
          referenceText = editor.getText()
          referenceCursorPosition = editor.getCursorScreenPosition()
          # do it again with enter and compare the results
          editor.setText(startingText)
          editor.setCursorScreenPosition(startingCursorPosition)
          keydown('d')
          keydown(keydownCodeForEnter)
          expect(editor.getText()).toEqual referenceText
          expect(editor.getCursorScreenPosition()).toEqual referenceCursorPosition

  describe "the gg keybinding", ->
    beforeEach ->
      editor.setText(" 1abc\n 2\n3\n")
      editor.setCursorScreenPosition([0, 2])

    describe "as a motion", ->
      describe "in command mode", ->
        beforeEach ->
          keydown('g')
          keydown('g')

        it "moves the cursor to the beginning of the first line", ->
          expect(editor.getCursorScreenPosition()).toEqual [0, 0]

      describe "in linewise visual mode", ->
        beforeEach ->
          editor.setCursorScreenPosition([1, 0])
          vimState.activateVisualMode('linewise')
          keydown('g')
          keydown('g')

        it "selects to the first line in the file", ->
          expect(editor.getSelectedText()).toBe " 1abc\n 2\n"

        it "moves the cursor to a specified line", ->
          expect(editor.getCursorScreenPosition()).toEqual [0, 0]

      describe "in characterwise visual mode", ->
        beforeEach ->
          editor.setCursorScreenPosition([1, 1])
          vimState.activateVisualMode()
          keydown('g')
          keydown('g')

        it "selects to the first line in the file", ->
          expect(editor.getSelectedText()).toBe "1abc\n 2"

        it "moves the cursor to a specified line", ->
          expect(editor.getCursorScreenPosition()).toEqual [0, 1]

    describe "as a repeated motion", ->
      describe "in command mode", ->
        beforeEach ->
          keydown('2')
          keydown('g')
          keydown('g')

        it "moves the cursor to a specified line", ->
          expect(editor.getCursorScreenPosition()).toEqual [1, 0]

      describe "in linewise visual motion", ->
        beforeEach ->
          editor.setCursorScreenPosition([2, 0])
          vimState.activateVisualMode('linewise')
          keydown('2')
          keydown('g')
          keydown('g')

        it "selects to a specified line", ->
          expect(editor.getSelectedText()).toBe " 2\n3\n"

        it "moves the cursor to a specified line", ->
          expect(editor.getCursorScreenPosition()).toEqual [1, 0]

      describe "in characterwise visual motion", ->
        beforeEach ->
          editor.setCursorScreenPosition([2, 0])
          vimState.activateVisualMode()
          keydown('2')
          keydown('g')
          keydown('g')

        it "selects to a first character of specified line", ->
          expect(editor.getSelectedText()).toBe "2\n3"

        it "moves the cursor to a specified line", ->
          expect(editor.getCursorScreenPosition()).toEqual [1, 1]

  describe "the G keybinding", ->
    beforeEach ->
      editor.setText("1\n    2\n 3abc\n ")
      editor.setCursorScreenPosition([0, 2])

    describe "as a motion", ->
      beforeEach -> keydown('G', shift: true)

      it "moves the cursor to the last line after whitespace", ->
        expect(editor.getCursorScreenPosition()).toEqual [3, 1]

    describe "as a repeated motion", ->
      beforeEach ->
        keydown('2')
        keydown('G', shift: true)

      it "moves the cursor to a specified line", ->
        expect(editor.getCursorScreenPosition()).toEqual [1, 4]

    describe "as a selection", ->
      beforeEach ->
        editor.setCursorScreenPosition([1, 0])
        vimState.activateVisualMode()
        keydown('G', shift: true)

      it "selects to the last line in the file", ->
        expect(editor.getSelectedText()).toBe "    2\n 3abc\n "

      it "moves the cursor to the last line after whitespace", ->
        expect(editor.getCursorScreenPosition()).toEqual [3,1]

  describe "the / keybinding", ->
    pane = null

    beforeEach ->
      pane = {activate: jasmine.createSpy("activate")}
      spyOn(atom.workspace, 'getActivePane').andReturn(pane)

      editor.setText("abc\ndef\nabc\ndef\n")
      editor.setCursorBufferPosition([0, 0])

    describe "as a motion", ->
      it "moves the cursor to the specified search pattern", ->
        keydown('/')

        editor.commandModeInputView.editor.setText 'def'
        editor.commandModeInputView.editor.trigger 'core:confirm'

        expect(editor.getCursorBufferPosition()).toEqual [1, 0]
        expect(pane.activate).toHaveBeenCalled()

      it "loops back around", ->
        editor.setCursorBufferPosition([3, 0])
        keydown('/')
        editor.commandModeInputView.editor.setText 'def'
        editor.commandModeInputView.editor.trigger 'core:confirm'

        expect(editor.getCursorBufferPosition()).toEqual [1, 0]

      it "uses a valid regex as a regex", ->
        keydown('/')
        # Cycle through the 'abc' on the first line with a character pattern
        editor.commandModeInputView.editor.setText '[abc]'
        editor.commandModeInputView.editor.trigger 'core:confirm'
        expect(editor.getCursorBufferPosition()).toEqual [0, 1]
        keydown('n')
        expect(editor.getCursorBufferPosition()).toEqual [0, 2]

      it "uses an invalid regex as a literal string", ->
        # Go straight to the literal [abc
        editor.setText("abc\n[abc]\n")
        keydown('/')
        editor.commandModeInputView.editor.setText '[abc'
        editor.commandModeInputView.editor.trigger 'core:confirm'
        expect(editor.getCursorBufferPosition()).toEqual [1, 0]
        keydown('n')
        expect(editor.getCursorBufferPosition()).toEqual [1, 0]

      it 'works with selection in visual mode', ->
        editor.setText('one two three')
        keydown('v')
        keydown('/')
        editor.commandModeInputView.editor.setText 'th'
        editor.commandModeInputView.editor.trigger 'core:confirm'
        expect(editor.getCursorBufferPosition()).toEqual [0, 9]
        keydown('d')
        expect(editor.getText()).toBe 'hree'

      it 'extends selection when repeating search in visual mode', ->
        editor.setText('line1\nline2\nline3')
        keydown('v')
        keydown('/')
        editor.commandModeInputView.editor.setText 'line'
        editor.commandModeInputView.editor.trigger 'core:confirm'
        {start, end} = editor.getSelectedBufferRange()
        expect(start.row).toEqual 0
        expect(end.row).toEqual 1
        keydown('n')
        {start,end} = editor.getSelectedBufferRange()
        expect(start.row).toEqual 0
        expect(end.row).toEqual 2

      describe "case sensitivity", ->
        beforeEach ->
          editor.setText("\nabc\nABC\n")
          editor.setCursorBufferPosition([0, 0])
          keydown('/')

        it "works in case sensitive mode", ->
          editor.commandModeInputView.editor.setText 'ABC'
          editor.commandModeInputView.editor.trigger 'core:confirm'
          expect(editor.getCursorBufferPosition()).toEqual [2, 0]
          keydown('n')
          expect(editor.getCursorBufferPosition()).toEqual [2, 0]

        it "works in case insensitive mode", ->
          editor.commandModeInputView.editor.setText '\\cAbC'
          editor.commandModeInputView.editor.trigger 'core:confirm'
          expect(editor.getCursorBufferPosition()).toEqual [1, 0]
          keydown('n')
          expect(editor.getCursorBufferPosition()).toEqual [2, 0]

        it "works in case insensitive mode wherever \\c is", ->
          editor.commandModeInputView.editor.setText 'AbC\\c'
          editor.commandModeInputView.editor.trigger 'core:confirm'
          expect(editor.getCursorBufferPosition()).toEqual [1, 0]
          keydown('n')
          expect(editor.getCursorBufferPosition()).toEqual [2, 0]

        it "uses case insensitive search if useSmartcaseForSearch is true and searching lowercase", ->
          atom.config.set 'vim-mode.useSmartcaseForSearch', true
          editor.commandModeInputView.editor.setText 'abc'
          editor.commandModeInputView.editor.trigger 'core:confirm'
          expect(editor.getCursorBufferPosition()).toEqual [1, 0]
          keydown('n')
          expect(editor.getCursorBufferPosition()).toEqual [2, 0]

        it "uses case sensitive search if useSmartcaseForSearch is true and searching uppercase", ->
          atom.config.set 'vim-mode.useSmartcaseForSearch', true
          editor.commandModeInputView.editor.setText 'ABC'
          editor.commandModeInputView.editor.trigger 'core:confirm'
          expect(editor.getCursorBufferPosition()).toEqual [2, 0]
          keydown('n')
          expect(editor.getCursorBufferPosition()).toEqual [2, 0]

      describe "repeating", ->
        it "does nothing with no search history", ->
          # This tests that no exception is raised
          keydown('n')

        beforeEach ->
          keydown('/')
          editor.commandModeInputView.editor.setText 'def'
          editor.commandModeInputView.editor.trigger 'core:confirm'

        describe "the n keybinding", ->
          it "repeats the last search", ->
            keydown('n')
            expect(editor.getCursorBufferPosition()).toEqual [3, 0]

        describe "the N keybinding", ->
          it "repeats the last search backwards", ->
            editor.setCursorBufferPosition([0, 0])
            keydown('N', shift: true)
            expect(editor.getCursorBufferPosition()).toEqual [3, 0]
            keydown('N', shift: true)
            expect(editor.getCursorBufferPosition()).toEqual [1, 0]

      describe "composing", ->
        it "composes with operators", ->
          keydown('d')
          keydown('/')
          editor.commandModeInputView.editor.setText('def')
          editor.commandModeInputView.editor.trigger('core:confirm')
          expect(editor.getText()).toEqual "def\nabc\ndef\n"

        it "repeats correctly with operators", ->
          keydown('d')
          keydown('/')
          editor.commandModeInputView.editor.setText('def')
          editor.commandModeInputView.editor.trigger('core:confirm')

          keydown('.')
          expect(editor.getText()).toEqual "def\n"

    describe "when reversed as ?", ->
      it "moves the cursor backwards to the specified search pattern", ->
        keydown('?')
        editor.commandModeInputView.editor.setText('def')
        editor.commandModeInputView.editor.trigger('core:confirm')
        expect(editor.getCursorBufferPosition()).toEqual [3, 0]

      describe "repeating", ->
        beforeEach ->
          keydown('?')
          editor.commandModeInputView.editor.setText('def')
          editor.commandModeInputView.editor.trigger('core:confirm')

        describe 'the n keybinding', ->
          it "repeats the last search backwards", ->
            editor.setCursorBufferPosition([0, 0])
            keydown('n')
            expect(editor.getCursorBufferPosition()).toEqual [3, 0]

        describe 'the N keybinding', ->
          it "repeats the last search forwards", ->
            editor.setCursorBufferPosition([0, 0])
            keydown('N', shift: true)
            expect(editor.getCursorBufferPosition()).toEqual [1, 0]

    describe "using search history", ->
      beforeEach ->
        keydown('/')
        editor.commandModeInputView.editor.setText('def')
        editor.commandModeInputView.editor.trigger('core:confirm')
        expect(editor.getCursorBufferPosition()).toEqual [1, 0]

        keydown('/')
        editor.commandModeInputView.editor.setText('abc')
        editor.commandModeInputView.editor.trigger('core:confirm')
        expect(editor.getCursorBufferPosition()).toEqual [2, 0]

      it "allows searching history in the search field", ->
        keydown('/')
        editor.commandModeInputView.editor.trigger('core:move-up')
        expect(editor.commandModeInputView.editor.getText()).toEqual('abc')
        editor.commandModeInputView.editor.trigger('core:move-up')
        expect(editor.commandModeInputView.editor.getText()).toEqual('def')
        editor.commandModeInputView.editor.trigger('core:move-up')
        expect(editor.commandModeInputView.editor.getText()).toEqual('def')

      it "resets the search field to empty when scrolling back", ->
        keydown('/')
        editor.commandModeInputView.editor.trigger('core:move-up')
        expect(editor.commandModeInputView.editor.getText()).toEqual('abc')
        editor.commandModeInputView.editor.trigger('core:move-up')
        expect(editor.commandModeInputView.editor.getText()).toEqual('def')
        editor.commandModeInputView.editor.trigger('core:move-down')
        expect(editor.commandModeInputView.editor.getText()).toEqual('abc')
        editor.commandModeInputView.editor.trigger('core:move-down')
        expect(editor.commandModeInputView.editor.getText()).toEqual ''

  describe "the * keybinding", ->
    beforeEach ->
      editor.setText("abc\n@def\nabc\ndef\n")
      editor.setCursorBufferPosition([0, 0])

    describe "as a motion", ->
      it "moves cursor to next occurence of word under cursor", ->
        keydown("*")
        expect(editor.getCursorBufferPosition()).toEqual [2, 0]

      it "doesn't move cursor unless next occurence is the exact word (no partial matches)", ->
        editor.setText("abc\ndef\nghiabc\njkl\nabcdef")
        editor.setCursorBufferPosition([0, 0])
        keydown("*")
        expect(editor.getCursorBufferPosition()).toEqual [0, 0]

      describe "with words that contain 'non-word' characters", ->
        it "moves cursor to next occurence of word under cursor", ->
          editor.setText("abc\n@def\nabc\n@def\n")
          editor.setCursorBufferPosition([1, 0])
          keydown("*")
          expect(editor.getCursorBufferPosition()).toEqual [3, 0]

        it "doesn't move cursor unless next match has exact word ending", ->
          editor.setText("abc\n@def\nabc\n@def1\n")
          # FIXME: I suspect there is a bug laying around
          # Cursor#getEndOfCurrentWordBufferPosition, this function
          # is returning '@' as a word, instead of returning the whole
          # word '@def', this behavior is avoided in this test, when we
          # execute the '*' command when cursor is on character after '@'
          # (in this particular example, the 'd' char)
          editor.setCursorBufferPosition([1, 1])
          keydown("*")
          expect(editor.getCursorBufferPosition()).toEqual [1, 0]

        # FIXME: This behavior is different from the one found in
        # vim. This is because the word boundary match in Javascript
        # ignores starting 'non-word' characters.
        # e.g.
        # in Vim:        /\<def\>/.test("@def") => false
        # in Javascript: /\bdef\b/.test("@def") => true
        it "moves cursor to the start of valid word char", ->
          editor.setText("abc\ndef\nabc\n@def\n")
          editor.setCursorBufferPosition([1, 0])
          keydown("*")
          expect(editor.getCursorBufferPosition()).toEqual [3, 1]

      describe "when cursor is on non-word char column", ->
        it "matches only the non-word char", ->
          editor.setText("abc\n@def\nabc\n@def\n")
          editor.setCursorBufferPosition([1, 0])
          keydown("*")
          expect(editor.getCursorBufferPosition()).toEqual [3, 0]

      describe "when cursor is not on a word", ->
        it "does a match with the next word", ->
          editor.setText("abc\na  @def\n abc\n @def")
          editor.setCursorBufferPosition([1, 1])
          keydown("*")
          expect(editor.getCursorBufferPosition()).toEqual [3, 1]

      describe "when cursor is at EOF", ->
        it "doesn't try to do any match", ->
          editor.setText("abc\n@def\nabc\n ")
          editor.setCursorBufferPosition([3, 0])
          keydown("*")
          expect(editor.getCursorBufferPosition()).toEqual [3, 0]

  describe "the hash keybinding", ->
    describe "as a motion", ->
      it "moves cursor to previous occurence of word under cursor", ->
        editor.setText("abc\n@def\nabc\ndef\n")
        editor.setCursorBufferPosition([2, 1])
        keydown("#")
        expect(editor.getCursorBufferPosition()).toEqual [0, 0]

      it "doesn't move cursor unless next occurence is the exact word (no partial matches)", ->
        editor.setText("abc\ndef\nghiabc\njkl\nabcdef")
        editor.setCursorBufferPosition([0, 0])
        keydown("#")
        expect(editor.getCursorBufferPosition()).toEqual [0, 0]

      describe "with words that containt 'non-word' characters", ->
        it "moves cursor to next occurence of word under cursor", ->
          editor.setText("abc\n@def\nabc\n@def\n")
          editor.setCursorBufferPosition([3, 0])
          keydown("#")
          expect(editor.getCursorBufferPosition()).toEqual [1, 0]

        it "moves cursor to the start of valid word char", ->
          editor.setText("abc\n@def\nabc\ndef\n")
          editor.setCursorBufferPosition([3, 0])
          keydown("#")
          expect(editor.getCursorBufferPosition()).toEqual [1, 1]

      describe "when cursor is on non-word char column", ->
        it "matches only the non-word char", ->
          editor.setText("abc\n@def\nabc\n@def\n")
          editor.setCursorBufferPosition([1, 0])
          keydown("*")
          expect(editor.getCursorBufferPosition()).toEqual [3, 0]

  describe "the H keybinding", ->
    beforeEach ->
      editor.setText("1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n")
      editor.setCursorScreenPosition([8, 0])
      spyOn(editor.getLastCursor(), 'setScreenPosition')

    it "moves the cursor to the first row if visible", ->
      spyOn(editor, 'getFirstVisibleScreenRow').andReturn(0)
      keydown('H', shift: true)
      expect(editor.getLastCursor().setScreenPosition).toHaveBeenCalledWith([0, 0])

    it "moves the cursor to the first visible row plus offset", ->
      spyOn(editor, 'getFirstVisibleScreenRow').andReturn(2)
      keydown('H', shift: true)
      expect(editor.getLastCursor().setScreenPosition).toHaveBeenCalledWith([4, 0])

    it "respects counts", ->
      spyOn(editor, 'getFirstVisibleScreenRow').andReturn(0)
      keydown('3')
      keydown('H', shift: true)
      expect(editor.getLastCursor().setScreenPosition).toHaveBeenCalledWith([2, 0])

  describe "the L keybinding", ->
    beforeEach ->
      editor.setText("1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n")
      editor.setCursorScreenPosition([8, 0])
      spyOn(editor.getLastCursor(), 'setScreenPosition')

    it "moves the cursor to the first row if visible", ->
      spyOn(editor, 'getLastVisibleScreenRow').andReturn(10)
      keydown('L', shift: true)
      expect(editor.getLastCursor().setScreenPosition).toHaveBeenCalledWith([10, 0])

    it "moves the cursor to the first visible row plus offset", ->
      spyOn(editor, 'getLastVisibleScreenRow').andReturn(6)
      keydown('L', shift: true)
      expect(editor.getLastCursor().setScreenPosition).toHaveBeenCalledWith([4, 0])

    it "respects counts", ->
      spyOn(editor, 'getLastVisibleScreenRow').andReturn(10)
      keydown('3')
      keydown('L', shift: true)
      expect(editor.getLastCursor().setScreenPosition).toHaveBeenCalledWith([8, 0])

  describe "the M keybinding", ->
    beforeEach ->
      editor.setText("1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n")
      editor.setCursorScreenPosition([8, 0])
      spyOn(editor.getLastCursor(), 'setScreenPosition')
      spyOn(editor, 'getLastVisibleScreenRow').andReturn(10)
      spyOn(editor, 'getFirstVisibleScreenRow').andReturn(0)

    it "moves the cursor to the first row if visible", ->
      keydown('M', shift: true)
      expect(editor.getLastCursor().setScreenPosition).toHaveBeenCalledWith([5, 0])

  describe 'the mark keybindings', ->
    beforeEach ->
      editor.setText('  12\n    34\n56\n')
      editor.setCursorBufferPosition([0,1])

    it 'moves to the beginning of the line of a mark', ->
      editor.setCursorBufferPosition([1,1])
      keydown('m')
      commandModeInputKeydown('a')
      editor.setCursorBufferPosition([0,0])
      keydown('\'')
      commandModeInputKeydown('a')
      expect(editor.getCursorBufferPosition()).toEqual [1,4]

    it 'moves literally to a mark', ->
      editor.setCursorBufferPosition([1,1])
      keydown('m')
      commandModeInputKeydown('a')
      editor.setCursorBufferPosition([0,0])
      keydown('`')
      commandModeInputKeydown('a')
      expect(editor.getCursorBufferPosition()).toEqual [1,1]

    it 'deletes to a mark by line', ->
      editor.setCursorBufferPosition([1,5])
      keydown('m')
      commandModeInputKeydown('a')
      editor.setCursorBufferPosition([0,0])
      keydown('d')
      keydown('\'')
      commandModeInputKeydown('a')
      expect(editor.getText()).toEqual '56\n'

    it 'deletes before to a mark literally', ->
      editor.setCursorBufferPosition([1,5])
      keydown('m')
      commandModeInputKeydown('a')
      editor.setCursorBufferPosition([0,1])
      keydown('d')
      keydown('`')
      commandModeInputKeydown('a')
      expect(editor.getText()).toEqual ' 4\n56\n'

    it 'deletes after to a mark literally', ->
      editor.setCursorBufferPosition([1,5])
      keydown('m')
      commandModeInputKeydown('a')
      editor.setCursorBufferPosition([2,1])
      keydown('d')
      keydown('`')
      commandModeInputKeydown('a')
      expect(editor.getText()).toEqual '  12\n    36\n'

    it 'moves back to previous', ->
      editor.setCursorBufferPosition([1,5])
      keydown('`')
      commandModeInputKeydown('`')
      editor.setCursorBufferPosition([2,1])
      keydown('`')
      commandModeInputKeydown('`')
      expect(editor.getCursorBufferPosition()).toEqual [1,5]

  describe 'the f/F keybindings', ->
    beforeEach ->
      editor.setText("abcabcabcabc\n")
      editor.setCursorScreenPosition([0, 0])

    it 'moves to the first specified character it finds', ->
      keydown('f')
      commandModeInputKeydown('c')
      expect(editor.getCursorScreenPosition()).toEqual [0, 2]

    it 'moves backwards to the first specified character it finds', ->
      editor.setCursorScreenPosition([0, 2])
      keydown('F', shift: true)
      commandModeInputKeydown('a')
      expect(editor.getCursorScreenPosition()).toEqual [0, 0]

    it 'respects count forward', ->
      keydown('2')
      keydown('f')
      commandModeInputKeydown('a')
      expect(editor.getCursorScreenPosition()).toEqual [0, 6]

    it 'respects count backward', ->
      editor.setCursorScreenPosition([0, 6])
      keydown('2')
      keydown('F', shift: true)
      commandModeInputKeydown('a')
      expect(editor.getCursorScreenPosition()).toEqual [0, 0]

    it "doesn't move if the character specified isn't found", ->
      keydown('f')
      commandModeInputKeydown('d')
      expect(editor.getCursorScreenPosition()).toEqual [0, 0]

    it "doesn't move if there aren't the specified count of the specified character", ->
      keydown('1')
      keydown('0')
      keydown('f')
      commandModeInputKeydown('a')
      expect(editor.getCursorScreenPosition()).toEqual [0, 0]
      # a bug was making this behaviour depend on the count
      keydown('1')
      keydown('1')
      keydown('f')
      commandModeInputKeydown('a')
      expect(editor.getCursorScreenPosition()).toEqual [0, 0]
      # and backwards now
      editor.setCursorScreenPosition([0, 6])
      keydown('1')
      keydown('0')
      keydown('F', shift: true)
      commandModeInputKeydown('a')
      expect(editor.getCursorScreenPosition()).toEqual [0, 6]
      keydown('1')
      keydown('1')
      keydown('F', shift: true)
      commandModeInputKeydown('a')
      expect(editor.getCursorScreenPosition()).toEqual [0, 6]

    it "composes with d", ->
      editor.setCursorScreenPosition([0,3])
      keydown('d')
      keydown('2')
      keydown('f')
      commandModeInputKeydown('a')
      expect(editor.getText()).toEqual 'abcbc\n'

  describe 'the t/T keybindings', ->
    beforeEach ->
      editor.setText("abcabcabcabc\n")
      editor.setCursorScreenPosition([0, 0])

    it 'moves to the character previous to the first specified character it finds', ->
      keydown('t')
      commandModeInputKeydown('a')
      expect(editor.getCursorScreenPosition()).toEqual [0, 2]
      # or stays put when it's already there
      keydown('t')
      commandModeInputKeydown('a')
      expect(editor.getCursorScreenPosition()).toEqual [0, 2]

    it 'moves backwards to the character after the first specified character it finds', ->
      editor.setCursorScreenPosition([0, 2])
      keydown('T', shift: true)
      commandModeInputKeydown('a')
      expect(editor.getCursorScreenPosition()).toEqual [0, 1]

    it 'respects count forward', ->
      keydown('2')
      keydown('t')
      commandModeInputKeydown('a')
      expect(editor.getCursorScreenPosition()).toEqual [0, 5]

    it 'respects count backward', ->
      editor.setCursorScreenPosition([0, 6])
      keydown('2')
      keydown('T', shift: true)
      commandModeInputKeydown('a')
      expect(editor.getCursorScreenPosition()).toEqual [0, 1]

    it "doesn't move if the character specified isn't found", ->
      keydown('t')
      commandModeInputKeydown('d')
      expect(editor.getCursorScreenPosition()).toEqual [0, 0]

    it "doesn't move if there aren't the specified count of the specified character", ->
      keydown('1')
      keydown('0')
      keydown('t')
      commandModeInputKeydown('a')
      expect(editor.getCursorScreenPosition()).toEqual [0, 0]
      # a bug was making this behaviour depend on the count
      keydown('1')
      keydown('1')
      keydown('t')
      commandModeInputKeydown('a')
      expect(editor.getCursorScreenPosition()).toEqual [0, 0]
      # and backwards now
      editor.setCursorScreenPosition([0, 6])
      keydown('1')
      keydown('0')
      keydown('T', shift: true)
      commandModeInputKeydown('a')
      expect(editor.getCursorScreenPosition()).toEqual [0, 6]
      keydown('1')
      keydown('1')
      keydown('T', shift: true)
      commandModeInputKeydown('a')
      expect(editor.getCursorScreenPosition()).toEqual [0, 6]

    it "composes with d", ->
      editor.setCursorScreenPosition([0,3])
      keydown('d')
      keydown('2')
      keydown('t')
      commandModeInputKeydown('b')
      expect(editor.getText()).toBe 'abcbcabc\n'

  describe 'the V keybinding', ->
    beforeEach ->
      editor.setText("01\n002\n0003\n00004\n000005\n")
      editor.setCursorScreenPosition([1, 1])

    it "selects down a line", ->
      keydown('V', shift: true)
      keydown('j')
      keydown('j')
      expect(editor.getSelectedText()).toBe "002\n0003\n00004\n"

    it "selects up a line", ->
      keydown('V', shift: true)
      keydown('k')
      expect(editor.getSelectedText()).toBe "01\n002\n"

  describe 'the ; and , keybindings', ->
    beforeEach ->
      editor.setText("abcabcabcabc\n")
      editor.setCursorScreenPosition([0, 0])

    it "repeat f in same direction", ->
      keydown('f')
      commandModeInputKeydown('c')
      expect(editor.getCursorScreenPosition()).toEqual [0, 2]
      keydown(';')
      expect(editor.getCursorScreenPosition()).toEqual [0, 5]
      keydown(';')
      expect(editor.getCursorScreenPosition()).toEqual [0, 8]

    it "repeat F in same direction", ->
      editor.setCursorScreenPosition([0,10])
      keydown('F', shift: true)
      commandModeInputKeydown('c')
      expect(editor.getCursorScreenPosition()).toEqual [0, 8]
      keydown(';')
      expect(editor.getCursorScreenPosition()).toEqual [0, 5]
      keydown(';')
      expect(editor.getCursorScreenPosition()).toEqual [0, 2]

    it "repeat f in opposite direction", ->
      editor.setCursorScreenPosition([0,6])
      keydown('f')
      commandModeInputKeydown('c')
      expect(editor.getCursorScreenPosition()).toEqual [0, 8]
      keydown(',')
      expect(editor.getCursorScreenPosition()).toEqual [0, 5]
      keydown(',')
      expect(editor.getCursorScreenPosition()).toEqual [0, 2]

    it "repeat F in opposite direction", ->
      editor.setCursorScreenPosition([0,4])
      keydown('F', shift: true)
      commandModeInputKeydown('c')
      expect(editor.getCursorScreenPosition()).toEqual [0, 2]
      keydown(',')
      expect(editor.getCursorScreenPosition()).toEqual [0, 5]
      keydown(',')
      expect(editor.getCursorScreenPosition()).toEqual [0, 8]

    it "alternate repeat f in same direction and reverse", ->
      keydown('f')
      commandModeInputKeydown('c')
      expect(editor.getCursorScreenPosition()).toEqual [0, 2]
      keydown(';')
      expect(editor.getCursorScreenPosition()).toEqual [0, 5]
      keydown(',')
      expect(editor.getCursorScreenPosition()).toEqual [0, 2]

    it "alternate repeat F in same direction and reverse", ->
      editor.setCursorScreenPosition([0,10])
      keydown('F', shift: true)
      commandModeInputKeydown('c')
      expect(editor.getCursorScreenPosition()).toEqual [0, 8]
      keydown(';')
      expect(editor.getCursorScreenPosition()).toEqual [0, 5]
      keydown(',')
      expect(editor.getCursorScreenPosition()).toEqual [0, 8]

    it "repeat t in same direction", ->
      keydown('t')
      commandModeInputKeydown('c')
      expect(editor.getCursorScreenPosition()).toEqual [0, 1]
      keydown(';')
      expect(editor.getCursorScreenPosition()).toEqual [0, 4]

    it "repeat T in same direction", ->
      editor.setCursorScreenPosition([0,10])
      keydown('T', shift: true)
      commandModeInputKeydown('c')
      expect(editor.getCursorScreenPosition()).toEqual [0, 9]
      keydown(';')
      expect(editor.getCursorScreenPosition()).toEqual [0, 6]

    it "repeat t in opposite direction first, and then reverse", ->
      editor.setCursorScreenPosition([0,3])
      keydown('t')
      commandModeInputKeydown('c')
      expect(editor.getCursorScreenPosition()).toEqual [0, 4]
      keydown(',')
      expect(editor.getCursorScreenPosition()).toEqual [0, 3]
      keydown(';')
      expect(editor.getCursorScreenPosition()).toEqual [0, 4]

    it "repeat T in opposite direction first, and then reverse", ->
      editor.setCursorScreenPosition([0,4])
      keydown('T', shift: true)
      commandModeInputKeydown('c')
      expect(editor.getCursorScreenPosition()).toEqual [0, 3]
      keydown(',')
      expect(editor.getCursorScreenPosition()).toEqual [0, 4]
      keydown(';')
      expect(editor.getCursorScreenPosition()).toEqual [0, 3]

    it "repeat with count in same direction", ->
      editor.setCursorScreenPosition([0,0])
      keydown('f')
      commandModeInputKeydown('c')
      expect(editor.getCursorScreenPosition()).toEqual [0, 2]
      keydown('2')
      keydown(';')
      expect(editor.getCursorScreenPosition()).toEqual [0, 8]

    it "repeat with count in reverse direction", ->
      editor.setCursorScreenPosition([0,6])
      keydown('f')
      commandModeInputKeydown('c')
      expect(editor.getCursorScreenPosition()).toEqual [0, 8]
      keydown('2')
      keydown(',')
      expect(editor.getCursorScreenPosition()).toEqual [0, 2]

  describe 'the % motion', ->
    beforeEach ->
      editor.setText("( ( ) )--{ text in here; and a function call(with parameters) }\n")
      editor.setCursorScreenPosition([0, 0])

    it 'matches the correct parenthesis', ->
      keydown('%')
      expect(editor.getCursorScreenPosition()).toEqual [0, 6]

    it 'matches the correct brace', ->
      editor.setCursorScreenPosition([0, 9])
      keydown('%')
      expect(editor.getCursorScreenPosition()).toEqual [0, 62]

    it 'composes correctly with d', ->
      editor.setCursorScreenPosition([0, 9])
      keydown('d')
      keydown('%')
      expect(editor.getText()).toEqual  "( ( ) )--\n"

    it 'moves correctly when composed with v going forward', ->
      keydown('v')
      keydown('h')
      keydown('%')
      expect(editor.getCursorScreenPosition()).toEqual [0, 7]

    it 'moves correctly when composed with v going backward', ->
      editor.setCursorScreenPosition([0, 5])
      keydown('v')
      keydown('%')
      expect(editor.getCursorScreenPosition()).toEqual [0, 0]

    it 'it moves appropriately to find the nearest matching action', ->
      editor.setCursorScreenPosition([0, 3])
      keydown('%')
      expect(editor.getCursorScreenPosition()).toEqual [0, 2]
      expect(editor.getText()).toEqual  "( ( ) )--{ text in here; and a function call(with parameters) }\n"

    it 'it moves appropriately to find the nearest matching action', ->
      editor.setCursorScreenPosition([0, 26])
      keydown('%')
      expect(editor.getCursorScreenPosition()).toEqual [0, 60]
      expect(editor.getText()).toEqual  "( ( ) )--{ text in here; and a function call(with parameters) }\n"

    it "finds matches across multiple lines", ->
      editor.setText("...(\n...)")
      editor.setCursorScreenPosition([0, 0])
      keydown("%")
      expect(editor.getCursorScreenPosition()).toEqual([1, 3])
