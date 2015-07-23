helpers = require './spec-helper'

describe "Insert mode commands", ->
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

  describe "Copy from line above/below", ->
    beforeEach ->
      editor.setText("12345\n\nabcd\nefghi")
      editor.setCursorBufferPosition([1, 0])
      editor.addCursorAtBufferPosition([3, 0])
      keydown 'i'

    describe "the ctrl-y command", ->
      it "copies from the line above", ->
        keydown 'y', ctrl: true
        expect(editor.getText()).toBe '12345\n1\nabcd\naefghi'

        editor.insertText ' '
        keydown 'y', ctrl: true
        expect(editor.getText()).toBe '12345\n1 3\nabcd\na cefghi'

      it "does nothing if there's nothing above the cursor", ->
        editor.insertText 'fill'
        keydown 'y', ctrl: true
        expect(editor.getText()).toBe '12345\nfill5\nabcd\nfillefghi'

        keydown 'y', ctrl: true
        expect(editor.getText()).toBe '12345\nfill5\nabcd\nfillefghi'

      it "does nothing on the first line", ->
        editor.setCursorBufferPosition([0, 2])
        editor.addCursorAtBufferPosition([3, 2])
        editor.insertText 'a'
        expect(editor.getText()).toBe '12a345\n\nabcd\nefaghi'
        keydown 'y', ctrl: true
        expect(editor.getText()).toBe '12a345\n\nabcd\nefadghi'

    describe "the ctrl-e command", ->
      beforeEach ->
        atom.keymaps.add "test",
          'atom-text-editor.vim-mode.insert-mode':
            'ctrl-e': 'vim-mode:copy-from-line-below'

      it "copies from the line below", ->
        keydown 'e', ctrl: true
        expect(editor.getText()).toBe '12345\na\nabcd\nefghi'

        editor.insertText ' '
        keydown 'e', ctrl: true
        expect(editor.getText()).toBe '12345\na c\nabcd\n efghi'

      it "does nothing if there's nothing below the cursor", ->
        editor.insertText 'foo'
        keydown 'e', ctrl: true
        expect(editor.getText()).toBe '12345\nfood\nabcd\nfooefghi'

        keydown 'e', ctrl: true
        expect(editor.getText()).toBe '12345\nfood\nabcd\nfooefghi'
