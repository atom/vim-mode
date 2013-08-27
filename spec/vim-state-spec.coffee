helpers = require './spec-helper'

describe "VimState", ->
  [editor, vimState] = []

  beforeEach ->
    vimMode = atom.loadPackage('vim-mode')
    vimMode.activateResources()

    editor = helpers.cacheEditor(editor)

    vimState = editor.vimState
    vimState.activateCommandMode()
    vimState.resetCommandMode()

  keydown = (key, options={}) ->
    options.element ?= editor[0]
    helpers.keydown(key, options)

  describe "initialization", ->
    it "puts the editor in command-mode initially", ->
      expect(editor).toHaveClass 'vim-mode'
      expect(editor).toHaveClass 'command-mode'

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
        expect(editor).toHaveClass 'visual-mode'
        expect(vimState.submode).toEqual 'characterwise'
        expect(editor).not.toHaveClass 'command-mode'

    describe "the V keybinding", ->
      beforeEach -> keydown('V', shift: true)

      it "puts the editor into visual characterwise mode", ->
        expect(editor).toHaveClass 'visual-mode'
        expect(vimState.submode).toEqual 'linewise'
        expect(editor).not.toHaveClass 'command-mode'

    describe "the ctrl-v keybinding", ->
      beforeEach -> keydown('v', ctrl: true)

      it "puts the editor into visual characterwise mode", ->
        expect(editor).toHaveClass 'visual-mode'
        expect(vimState.submode).toEqual 'blockwise'
        expect(editor).not.toHaveClass 'command-mode'

    describe "the i keybinding", ->
      beforeEach -> keydown('i')

      it "puts the editor into insert mode", ->
        expect(editor).toHaveClass 'insert-mode'
        expect(editor).not.toHaveClass 'command-mode'

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

      describe "on a line with content", ->
        beforeEach -> editor.setCursorScreenPosition([0, 6])

        it "allows the cursor to be placed on the \n character", ->
          expect(editor.getCursorScreenPosition()).toEqual [0, 6]

    it "puts the editor into command mode when <escape> is pressed", ->
      keydown('escape')

      expect(editor).toHaveClass 'command-mode'
      expect(editor).not.toHaveClass 'insert-mode'

    it "puts the editor into command mode when <ctrl-c> is pressed", ->
      keydown('c', ctrl: true)

      expect(editor).toHaveClass 'command-mode'
      expect(editor).not.toHaveClass 'insert-mode'

  describe "visual-mode", ->
    beforeEach -> keydown('v')

    it "puts the editor into command mode when <escape> is pressed", ->
      keydown('escape')

      expect(editor).toHaveClass 'command-mode'
      expect(editor).not.toHaveClass 'visual-mode'
