helpers = require './spec-helper'

describe "Scrolling", ->
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

  describe "scrolling keybindings", ->
    beforeEach ->
      editor.setText("1\n2\n3\n4\n5\n6\n7\n8\n9\n10")
      spyOn(editorView, 'getFirstVisibleScreenRow').andReturn(2)
      spyOn(editorView, 'getLastVisibleScreenRow').andReturn(8)
      spyOn(editorView, 'scrollToScreenPosition')

    describe "the ctrl-e keybinding", ->
      beforeEach ->
        spyOn(editor, 'getCursorScreenPosition').andReturn({row: 4, column: 0})
        spyOn(editor, 'setCursorScreenPosition')

      it "moves the screen down by one and keeps cursor onscreen", ->
        keydown('e', ctrl: true)
        expect(editorView.scrollToScreenPosition).toHaveBeenCalledWith([7, 0])
        expect(editor.setCursorScreenPosition).toHaveBeenCalledWith([6, 0])

    describe "the ctrl-y keybinding", ->
      beforeEach ->
        spyOn(editor, 'getCursorScreenPosition').andReturn({row: 6, column: 0})
        spyOn(editor, 'setCursorScreenPosition')

      it "moves the screen up by one and keeps the cursor onscreen", ->
        keydown('y', ctrl: true)
        expect(editorView.scrollToScreenPosition).toHaveBeenCalledWith([3, 0])
        expect(editor.setCursorScreenPosition).toHaveBeenCalledWith([4, 0])
