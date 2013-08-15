$ = require 'jquery'

Keymap = require 'keymap'

helpers = require './spec-helper'

describe "VimState", ->
  [editor, vimState, originalKeymap] = []
  keydown = helpers.keydown

  beforeEach ->
    originalKeymap = window.keymap
    window.keymap = new Keymap

    vimMode = atom.loadPackage('vim-mode')
    vimMode.activateResources()

    editor = helpers.cacheEditor(editor)

    vimState = editor.vimState
    vimState.activateCommandMode()
    vimState.resetCommandMode()

  afterEach ->
    window.keymap = originalKeymap

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
