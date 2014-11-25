helpers = require './spec-helper'
VimState = require '../lib/vim-state'
StatusBarManager = require '../lib/status-bar-manager'

describe "VimState", ->
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

  describe "initialization", ->
    it "puts the editor in command-mode initially by default", ->
      expect(editorElement.classList.contains('vim-mode')).toBe(true)
      expect(editorElement.classList.contains('command-mode')).toBe(true)

    it "puts the editor in insert-mode if startInInsertMode is true", ->
      atom.config.set 'vim-mode.startInInsertMode', true
      editor.vimState = new VimState(editorElement, new StatusBarManager)
      expect(editorElement.classList.contains('insert-mode')).toBe(true)

  describe "::destroy", ->
    it "re-enables text input on the editor", ->
      expect(editorElement.component.isInputEnabled()).toBeFalsy()
      vimState.destroy()
      expect(editorElement.component.isInputEnabled()).toBeTruthy()

    it "removes the mode classes from the editor", ->
      expect(editorElement.classList.contains("command-mode")).toBeTruthy()
      vimState.destroy()
      expect(editorElement.classList.contains("command-mode")).toBeFalsy()

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
        expect(editorElement.classList.contains('visual-mode')).toBe(true)
        expect(vimState.submode).toEqual 'characterwise'
        expect(editorElement.classList.contains('command-mode')).toBe(false)

    describe "the V keybinding", ->
      beforeEach ->
        editor.setText("012345\nabcdef")
        editor.setCursorScreenPosition([0, 0])
        keydown('V', shift: true)

      it "puts the editor into visual linewise mode", ->
        expect(editorElement.classList.contains('visual-mode')).toBe(true)
        expect(vimState.submode).toEqual 'linewise'
        expect(editorElement.classList.contains('command-mode')).toBe(false)

      it "selects the current line", ->
        expect(editor.getLastSelection().getText()).toEqual '012345\n'

    describe "the ctrl-v keybinding", ->
      beforeEach -> keydown('v', ctrl: true)

      it "puts the editor into visual characterwise mode", ->
        expect(editorElement.classList.contains('visual-mode')).toBe(true)
        expect(vimState.submode).toEqual 'blockwise'
        expect(editorElement.classList.contains('command-mode')).toBe(false)

    describe "the i keybinding", ->
      beforeEach -> keydown('i')

      it "puts the editor into insert mode", ->
        expect(editorElement.classList.contains('insert-mode')).toBe(true)
        expect(editorElement.classList.contains('command-mode')).toBe(false)

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

    describe 'with character-input operations', ->
      beforeEach -> editor.setText('012345\nabcdef')

      it 'properly clears the opStack', ->
        keydown('d')
        keydown('r')
        expect(vimState.mode).toBe 'command'
        expect(vimState.opStack.length).toBe 0
        commandModeInputKeydown('escape')
        keydown('d')
        expect(editor.getText()).toBe '012345\nabcdef'

  describe "insert-mode", ->
    beforeEach ->
      keydown('i')

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

      expect(editorElement.classList.contains('command-mode')).toBe(true)
      expect(editorElement.classList.contains('insert-mode')).toBe(false)
      expect(editorElement.classList.contains('visual-mode')).toBe(false)

    it "puts the editor into command mode when <ctrl-c> is pressed", ->
      helpers.mockPlatform(editorElement, 'platform-darwin')
      keydown('c', ctrl: true)
      helpers.unmockPlatform(editorElement)

      expect(editorElement.classList.contains('command-mode')).toBe(true)
      expect(editorElement.classList.contains('insert-mode')).toBe(false)
      expect(editorElement.classList.contains('visual-mode')).toBe(false)

  describe "visual-mode", ->
    beforeEach -> keydown('v')

    it "puts the editor into command mode when <escape> is pressed", ->
      keydown('escape')

      expect(editorElement.classList.contains('command-mode')).toBe(true)
      expect(editorElement.classList.contains('visual-mode')).toBe(false)

    describe "motions", ->
      beforeEach ->
        editor.setText("012345\n\nabcdef")
        editor.setCursorScreenPosition([0, 0])
        keydown('w')

      it "execute instead of select", ->
        expect(editor.getLastSelection().getText()).toEqual '012345'

    describe "operators", ->
      beforeEach ->
        editor.setText("012345\n\nabcdef")
        editor.setCursorScreenPosition([0, 0])
        editor.selectLinesContainingCursors()
        keydown('d')

      it "operate on the current selection", ->
        expect(editor.getText()).toEqual "\nabcdef"

    describe "returning to command-mode", ->
      beforeEach ->
        editor.setText("012345\n\nabcdef")
        editor.selectLinesContainingCursors()
        keydown('escape')

      it "operate on the current selection", ->
        expect(editor.getLastSelection().getText()).toEqual ''

  describe "marks", ->
    beforeEach ->  editor.setText("text in line 1\ntext in line 2\ntext in line 3")

    it "basic marking functionality", ->
      editor.setCursorScreenPosition([1, 1])
      keydown('m')
      commandModeInputKeydown('t')
      expect(editor.getText()).toEqual "text in line 1\ntext in line 2\ntext in line 3"
      editor.setCursorScreenPosition([2, 2])
      keydown('`')
      commandModeInputKeydown('t')
      expect(editor.getCursorScreenPosition()).toEqual [1,1]

    it "real (tracking) marking functionality", ->
      editor.setCursorScreenPosition([2, 2])
      keydown('m')
      commandModeInputKeydown('q')
      editor.setCursorScreenPosition([1, 2])
      keydown('o')
      keydown('escape')
      keydown('`')
      commandModeInputKeydown('q')
      expect(editor.getCursorScreenPosition()).toEqual [3,2]

    it "real (tracking) marking functionality", ->
      editor.setCursorScreenPosition([2, 2])
      keydown('m')
      commandModeInputKeydown('q')
      editor.setCursorScreenPosition([1, 2])
      keydown('d')
      keydown('d')
      keydown('escape')
      keydown('`')
      commandModeInputKeydown('q')
      expect(editor.getCursorScreenPosition()).toEqual [1,2]
