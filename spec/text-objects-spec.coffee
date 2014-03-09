helpers = require './spec-helper'

describe "Text Objects", ->
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

  describe "inner word", ->
    beforeEach ->
      editor.setText("Lorem ipsum dolor sit amet...")

    describe "as a selection", ->
      it "selects when cursor is at beginning", ->
        editor.setCursorScreenPosition([0, 6])
        keydown('y')
        keydown('i')
        keydown('w')

        expect(vimState.getRegister('"').text).toBe 'ipsum'
        expect(editor.getCursorScreenPosition()).toEqual [0, 6]

      it "selects when cursor is in middle", ->
        editor.setCursorScreenPosition([0, 8])
        keydown('y')
        keydown('i')
        keydown('w')

        expect(vimState.getRegister('"').text).toBe 'ipsum'
        expect(editor.getCursorScreenPosition()).toEqual [0, 6]
