helpers = require './spec-helper'

describe "VimState", ->
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

  describe "initialization", ->
    it "puts the editor in command-mode initially", ->
      expect(editorView).toHaveClass 'vim-mode'
      expect(editorView).toHaveClass 'command-mode'

  describe "command-mode", ->
    describe "when entering an insertable character", ->
      beforeEach -> keydown('\\')

      it "stops propagation", ->
        expect(editor.getText()).toEqual ''

    describe "when entering an operator", ->
      beforeEach -> keydown('d')

      describe "with an operator that can't be composed", ->
        beforeEach -> keydown('x')

        it "clears the operator stack", ->
          expect(vimState.opStack.length).toBe 0

      describe "the escape keybinding", ->
        beforeEach -> keydown('escape')

        it "clears the operator stack", ->
          expect(vimState.opStack.length).toBe 0

      describe "the ctrl-c keybinding", ->
        beforeEach -> keydown('c', ctrl: true)

        it "clears the operator stack", ->
          expect(vimState.opStack.length).toBe 0

    describe "the v keybinding", ->
      beforeEach -> keydown('v')

      it "puts the editor into visual characterwise mode", ->
        expect(editorView).toHaveClass 'visual-mode'
        expect(vimState.submode).toEqual 'characterwise'
        expect(editorView).not.toHaveClass 'command-mode'

    describe "the V keybinding", ->
      beforeEach ->
        editor.setText("012345\nabcdef")
        editor.setCursorScreenPosition([0, 0])
        keydown('V', shift: true)

      it "puts the editor into visual linewise mode", ->
        expect(editorView).toHaveClass 'visual-mode'
        expect(vimState.submode).toEqual 'linewise'
        expect(editorView).not.toHaveClass 'command-mode'

      it "selects the current line", ->
        expect(editor.getSelection().getText()).toEqual '012345\n'

    describe "the ctrl-v keybinding", ->
      beforeEach -> keydown('v', ctrl: true)

      it "puts the editor into visual characterwise mode", ->
        expect(editorView).toHaveClass 'visual-mode'
        expect(vimState.submode).toEqual 'blockwise'
        expect(editorView).not.toHaveClass 'command-mode'

    describe "the i keybinding", ->
      beforeEach -> keydown('i')

      it "puts the editor into insert mode", ->
        expect(editorView).toHaveClass 'insert-mode'
        expect(editorView).not.toHaveClass 'command-mode'

    describe "with content", ->
      beforeEach -> editor.setText("012345\n\nabcdef")

      # FIXME: See atom/vim-mode#2
      xdescribe "on a line with content", ->
        beforeEach -> editor.setCursorScreenPosition([0, 6])

        it "does not allow the cursor to be placed on the \n character", ->
          expect(editor.getCursorScreenPosition()).toEqual [0, 5]

      describe "on an empty line", ->
        beforeEach -> editor.setCursorScreenPosition([1, 0])

        it "allows the cursor to be placed on the \n character", ->
          expect(editor.getCursorScreenPosition()).toEqual [1, 0]

  describe "insert-mode", ->
    beforeEach -> keydown('i')

    describe "with content", ->
      beforeEach -> editor.setText("012345\n\nabcdef")

      describe "when cursor is in the middle of the line", ->
        beforeEach -> editor.setCursorScreenPosition([0,3])

        it "moves the cursor to the left when exiting insert mode", ->
          keydown('escape')
          expect(editor.getCursorScreenPosition()).toEqual [0,2]

      describe "when cursor is at the beginning of line", ->
        beforeEach -> editor.setCursorScreenPosition([1,0])

        it "leaves the cursor at the beginning of line", ->
          keydown('escape')
          expect(editor.getCursorScreenPosition()).toEqual [1,0]

      describe "on a line with content", ->
        beforeEach -> editor.setCursorScreenPosition([0, 6])

        it "allows the cursor to be placed on the \n character", ->
          expect(editor.getCursorScreenPosition()).toEqual [0, 6]

    it "puts the editor into command mode when <escape> is pressed", ->
      keydown('escape')

      expect(editorView).toHaveClass 'command-mode'
      expect(editorView).not.toHaveClass 'insert-mode'

    it "puts the editor into command mode when <ctrl-c> is pressed", ->
      keydown('c', ctrl: true)

      expect(editorView).toHaveClass 'command-mode'
      expect(editorView).not.toHaveClass 'insert-mode'

  describe "visual-mode", ->
    beforeEach -> keydown('v')

    it "puts the editor into command mode when <escape> is pressed", ->
      keydown('escape')

      expect(editorView).toHaveClass 'command-mode'
      expect(editorView).not.toHaveClass 'visual-mode'

    describe "motions", ->
      beforeEach ->
        editor.setText("012345\n\nabcdef")
        editor.setCursorScreenPosition([0, 0])
        keydown('w')

      it "execute instead of select", ->
        expect(editor.getSelection().getText()).toEqual '012345'

    describe "operators", ->
      beforeEach ->
        editor.setText("012345\n\nabcdef")
        editor.setCursorScreenPosition([0, 0])
        editor.selectLine()
        keydown('d')

      it "operate on the current selection", ->
        expect(editor.getText()).toEqual "\nabcdef"

    describe "returning to command-mode", ->
      beforeEach ->
        editor.setText("012345\n\nabcdef")
        editor.selectLine()
        keydown('escape')

      it "operate on the current selection", ->
        expect(editor.getSelection().getText()).toEqual ''
