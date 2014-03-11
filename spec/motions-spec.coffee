helpers = require './spec-helper'

describe "Motions", ->
  [editor, editorView, vimState] = []

  beforeEach ->
    vimMode = atom.packages.loadPackage('vim-mode')
    vimMode.activateResources()

    editorView = helpers.cacheEditor(editorView)
    editor = editorView.editor

    vimState = editorView.vimState
    vimState.activateCommandMode()
    vimState.resetCommandMode()

  keydown = (key, options={}) ->
    options.element ?= editorView[0]
    helpers.keydown(key, options)

  describe "simple motions", ->
    beforeEach ->
      editor.setText("12345\nabcde\nABCDE")
      editor.setCursorScreenPosition([1, 1])

    describe "the h keybinding", ->
      describe "as a motion", ->
        it "moves the cursor left, but not to the previous line", ->
          keydown('h')
          expect(editor.getCursorScreenPosition()).toEqual [1, 0]

          keydown('h')
          expect(editor.getCursorScreenPosition()).toEqual [1, 0]

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

    describe "the k keybinding", ->
      it "moves the cursor up, but not to the beginning of the first line", ->
        keydown('k')
        expect(editor.getCursorScreenPosition()).toEqual [0, 1]

        keydown('k')
        expect(editor.getCursorScreenPosition()).toEqual [0, 1]

    describe "the l keybinding", ->
      beforeEach -> editor.setCursorScreenPosition([1, 3])

      it "moves the cursor right, but not to the next line", ->
        keydown('l')
        expect(editor.getCursorScreenPosition()).toEqual [1, 4]

        keydown('l')
        expect(editor.getCursorScreenPosition()).toEqual [1, 4]

  describe "the w keybinding", ->
    beforeEach -> editor.setText("ab cde1+- \n xyz\n\nzip")

    describe "as a motion", ->
      beforeEach -> editor.setCursorScreenPosition([0, 0])

      xit "moves the cursor to the beginning of the next word", ->
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
        expect(editor.getCursorScreenPosition()).toEqual [3, 2]

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
        expect(editor.getCursorScreenPosition()).toEqual [2, 0]

    describe "as a selection", ->
      describe "within a word", ->

        it "selects to the end of the whole word", ->
          editor.setCursorScreenPosition([0, 0])
          keydown('y')
          keydown('W', shift:true)
          expect(vimState.getRegister('"').text).toBe 'cde1+- '

        it "doesn't go past the end of the file", ->
          editor.setCursorScreenPosition([2, 0])
          keydown('y')
          keydown('W', shift:true)
          expect(vimState.getRegister('"').text).toBe ''

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

        # INCOMPATIBILITY: vim doesn't stop at [2, 0] it advances immediately
        # to [3, 2]
        keydown('e')
        expect(editor.getCursorScreenPosition()).toEqual [2, 0]

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

        # FIXME: The definition of Cursor#getMovePreviousWordBoundaryBufferPosition
        # will always stop on the last word in the buffer. The question is should
        # we change this behavior.
        #
        # See atom/vim-mode#3
        #keydown('b')
        #expect(editor.getCursorScreenPosition()).toEqual [0, 0]

        #keydown('b')
        #expect(editor.getCursorScreenPosition()).toEqual [0, 0]

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
    beforeEach -> editor.setText("cde1+- ab \n xyz-123\n\n zip")

    describe "as a motion", ->
      beforeEach -> editor.setCursorScreenPosition([4, 1])

      it "moves the cursor to the beginning of the previous word", ->
        keydown('B', shift:true)
        expect(editor.getCursorScreenPosition()).toEqual [3, 1]

        keydown('B', shift:true)
        expect(editor.getCursorScreenPosition()).toEqual [2, 0]

        keydown('B', shift:true)
        expect(editor.getCursorScreenPosition()).toEqual [1, 1]

        keydown('B', shift:true)
        expect(editor.getCursorScreenPosition()).toEqual [0, 7]

        keydown('B', shift:true)
        expect(editor.getCursorScreenPosition()).toEqual [0, 0]

    describe "as a selection", ->
      it "selects to the beginning of the whole word", ->
        editor.setCursorScreenPosition([1, 8])
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
      editor.setCursorScreenPosition([0, 4])

    describe "as a motion", ->
      beforeEach -> keydown('^')

      it "moves the cursor to the beginning of the line", ->
        expect(editor.getCursorScreenPosition()).toEqual [0, 2]

    describe "as a selection", ->
      beforeEach ->
        keydown('d')
        keydown('^')

      it 'selects to the beginning of the lines', ->
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
      editor.setText("  abcde\n")
      editor.setCursorScreenPosition([0, 4])

    describe "as a motion", ->
      beforeEach -> keydown('$')

      # FIXME: See atom/vim-mode#2
      xit "moves the cursor to the end of the line", ->
        expect(editor.getCursorScreenPosition()).toEqual [0, 6]

    describe "as a selection", ->
      beforeEach ->
        keydown('d')
        keydown('$')

      it "selects to the beginning of the lines", ->
        expect(editor.getText()).toBe "  ab\n"
        # FIXME: See atom/vim-mode#2
        #expect(editor.getCursorScreenPosition()).toEqual [0, 3]

  # FIXME: this doesn't work as we can't determine if this is a motion
  # or part of a repeat prefix.
  xdescribe "the 0 keybinding", ->
    beforeEach ->
      editor.setText("  a\n")
      editor.setCursorScreenPosition([0, 2])

    describe "as a motion", ->
      beforeEach -> keydown('0')

      it "moves the cursor to the beginning of the line", ->
        expect(editor.getCursorScreenPosition()).toEqual [0,0]

  describe "the gg keybinding", ->
    beforeEach ->
      editor.setText(" 1abc\n2\n3\n")
      editor.setCursorScreenPosition([0, 2])

    describe "as a motion", ->
      beforeEach ->
        keydown('g')
        keydown('g')

      it "moves the cursor to the beginning of the first line", ->
        expect(editor.getCursorScreenPosition()).toEqual [0, 1]

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

  describe "the / keybinding", ->
    beforeEach ->
      editor.setText("abc\ndef\nabc\ndef\n")
      editor.setCursorBufferPosition([0, 0])

    describe "as a motion", ->
      it "moves the cursor to the specified search pattern", ->
        keydown('/')

        editor.commandModeInputView.editor.setText 'def'
        editor.commandModeInputView.editor.trigger 'core:confirm'

        expect(editor.getCursorBufferPosition()).toEqual [1, 0]

      it "loops back around", ->
        editor.setCursorBufferPosition([3, 0])
        keydown('/')
        editor.commandModeInputView.editor.setText 'def'
        editor.commandModeInputView.editor.trigger 'core:confirm'

        expect(editor.getCursorBufferPosition()).toEqual [1, 0]

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

  describe "the H keybinding", ->
    beforeEach ->
      editor.setText("1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n")
      editor.setCursorScreenPosition([8, 0])
      spyOn(editor, 'setCursorScreenPosition')

    it "moves the cursor to the first row if visible", ->
      spyOn(editorView, 'getFirstVisibleScreenRow').andReturn(0)
      keydown('H', shift: true)
      expect(editor.setCursorScreenPosition).toHaveBeenCalledWith([0, 0])

    it "moves the cursor to the first visible row plus offset", ->
      spyOn(editorView, 'getFirstVisibleScreenRow').andReturn(2)
      keydown('H', shift: true)
      expect(editor.setCursorScreenPosition).toHaveBeenCalledWith([4, 0])

    it "respects counts", ->
      spyOn(editorView, 'getFirstVisibleScreenRow').andReturn(0)
      keydown('3')
      keydown('H', shift: true)
      expect(editor.setCursorScreenPosition).toHaveBeenCalledWith([2, 0])

  describe "the L keybinding", ->
    beforeEach ->
      editor.setText("1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n")
      editor.setCursorScreenPosition([8, 0])
      spyOn(editor, 'setCursorScreenPosition')

    it "moves the cursor to the first row if visible", ->
      spyOn(editorView, 'getLastVisibleScreenRow').andReturn(10)
      keydown('L', shift: true)
      expect(editor.setCursorScreenPosition).toHaveBeenCalledWith([10, 0])

    it "moves the cursor to the first visible row plus offset", ->
      spyOn(editorView, 'getLastVisibleScreenRow').andReturn(6)
      keydown('L', shift: true)
      expect(editor.setCursorScreenPosition).toHaveBeenCalledWith([4, 0])

    it "respects counts", ->
      spyOn(editorView, 'getLastVisibleScreenRow').andReturn(10)
      keydown('3')
      keydown('L', shift: true)
      expect(editor.setCursorScreenPosition).toHaveBeenCalledWith([8, 0])

  describe "the M keybinding", ->
    beforeEach ->
      editor.setText("1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n")
      editor.setCursorScreenPosition([8, 0])
      spyOn(editor, 'setCursorScreenPosition')
      spyOn(editorView, 'getLastVisibleScreenRow').andReturn(10)
      spyOn(editorView, 'getFirstVisibleScreenRow').andReturn(0)

    it "moves the cursor to the first row if visible", ->
      keydown('M', shift: true)
      expect(editor.setCursorScreenPosition).toHaveBeenCalledWith([5, 0])
