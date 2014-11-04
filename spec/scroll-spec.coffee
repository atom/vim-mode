helpers = require './spec-helper'

describe "Scrolling", ->
  [editor, editorView, vimState] = []

  beforeEach ->
    vimMode = atom.packages.loadPackage('vim-mode')
    vimMode.activateResources()

    helpers.getEditorView editorView, (view) ->
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

  describe "scrolling relative to cursor", ->
    beforeEach ->
      editor.setText("1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n11\n12\n13\n14\n15\n16\n17\n18\n19\n20")
      spyOn(editorView, 'getFirstVisibleScreenRow').andReturn(7)
      spyOn(editorView, 'getLastVisibleScreenRow').andReturn(14)
      spyOn(editor, 'getRowsPerPage').andReturn(8)
      spyOn(editorView, 'scrollToScreenPosition')

    describe "the zt keybinding", ->
      beforeEach ->
        spyOn(editor, 'getCursorScreenPosition').andReturn({row: 9, column: 0})
        spyOn(editor, 'setCursorScreenPosition')

      it "moves the screen up and let the cursor line to fit the screen top", ->
        keydown('z')
        keydown('t')
        expect(editorView.scrollToScreenPosition).toHaveBeenCalledWith([9, 0])

    describe "the zb keybinding", ->
      beforeEach ->
        spyOn(editor, 'getCursorScreenPosition').andReturn({row: 9, column: 0})
        spyOn(editor, 'setCursorScreenPosition')

      it "moves the screen down and let the cursor line to fit the screen bottom", ->
        keydown('z')
        keydown('b')
        expect(editorView.scrollToScreenPosition).toHaveBeenCalledWith([9, 0])

    describe "the zz keybinding", ->
      beforeEach ->
        spyOn(editor, 'getCursorScreenPosition').andReturn({row: 9, column: 0})
        spyOn(editor, 'setCursorScreenPosition')

      it "moves the screen to let the cursor line to fit the screen middle", ->
        keydown('z')
        keydown('z')
        expect(editorView.scrollToScreenPosition).toHaveBeenCalledWith([7, 0])
