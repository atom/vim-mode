helpers = require './spec-helper'

describe "Scrolling", ->
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

  describe "scrolling keybindings", ->
    beforeEach ->
      editor.setText("1\n2\n3\n4\n5\n6\n7\n8\n9\n10")
      spyOn(editor, 'getFirstVisibleScreenRow').andReturn(2)
      spyOn(editor, 'getLastVisibleScreenRow').andReturn(8)
      spyOn(editor, 'scrollToScreenPosition')

    describe "the ctrl-e keybinding", ->
      beforeEach ->
        spyOn(editor, 'getCursorScreenPosition').andReturn({row: 4, column: 0})
        spyOn(editor, 'setCursorScreenPosition')

      it "moves the screen down by one and keeps cursor onscreen", ->
        keydown('e', ctrl: true)
        expect(editor.scrollToScreenPosition).toHaveBeenCalledWith([7, 0])
        expect(editor.setCursorScreenPosition).toHaveBeenCalledWith([6, 0])

    describe "the ctrl-y keybinding", ->
      beforeEach ->
        spyOn(editor, 'getCursorScreenPosition').andReturn({row: 6, column: 0})
        spyOn(editor, 'setCursorScreenPosition')

      it "moves the screen up by one and keeps the cursor onscreen", ->
        keydown('y', ctrl: true)
        expect(editor.scrollToScreenPosition).toHaveBeenCalledWith([3, 0])
        expect(editor.setCursorScreenPosition).toHaveBeenCalledWith([4, 0])

  describe "scroll cursor keybindings", ->
    beforeEach ->
      text = ""
      for i in [1..200]
        text += "#{i}\n"
      editor.setText(text)

      spyOn(editor, 'moveToFirstCharacterOfLine')
      spyOn(editor, 'getLineHeightInPixels').andReturn(20)
      spyOn(editor, 'setScrollTop')
      spyOn(editor, 'getHeight').andReturn(200)
      spyOn(editor, 'getFirstVisibleScreenRow').andReturn(90)
      spyOn(editor, 'getLastVisibleScreenRow').andReturn(110)

    describe "the z<CR> keybinding", ->
      keydownCodeForEnter = '\r'

      beforeEach ->
        spyOn(editor, 'pixelPositionForScreenPosition').andReturn({top: 1000, left: 0})

      it "moves the screen to position cursor at the top of the window and moves cursor to first non-blank in the line", ->
        keydown('z')
        keydown(keydownCodeForEnter)
        expect(editor.setScrollTop).toHaveBeenCalledWith(960)
        expect(editor.moveToFirstCharacterOfLine).toHaveBeenCalled()

    describe "the zt keybinding", ->
      beforeEach ->
        spyOn(editor, 'pixelPositionForScreenPosition').andReturn({top: 1000, left: 0})

      it "moves the screen to position cursor at the top of the window and leave cursor in the same column", ->
        keydown('z')
        keydown('t')
        expect(editor.setScrollTop).toHaveBeenCalledWith(960)
        expect(editor.moveToFirstCharacterOfLine).not.toHaveBeenCalled()

    describe "the z. keybinding", ->
      beforeEach ->
        spyOn(editor, 'pixelPositionForScreenPosition').andReturn({top: 1000, left: 0})

      it "moves the screen to position cursor at the center of the window and moves cursor to first non-blank in the line", ->
        keydown('z')
        keydown('.')
        expect(editor.setScrollTop).toHaveBeenCalledWith(900)
        expect(editor.moveToFirstCharacterOfLine).toHaveBeenCalled()

    describe "the zz keybinding", ->
      beforeEach ->
        spyOn(editor, 'pixelPositionForScreenPosition').andReturn({top: 1000, left: 0})

      it "moves the screen to position cursor at the center of the window and leave cursor in the same column", ->
        keydown('z')
        keydown('z')
        expect(editor.setScrollTop).toHaveBeenCalledWith(900)
        expect(editor.moveToFirstCharacterOfLine).not.toHaveBeenCalled()

    describe "the z- keybinding", ->
      beforeEach ->
        spyOn(editor, 'pixelPositionForScreenPosition').andReturn({top: 1000, left: 0})

      it "moves the screen to position cursor at the bottom of the window and moves cursor to first non-blank in the line", ->
        keydown('z')
        keydown('-')
        expect(editor.setScrollTop).toHaveBeenCalledWith(860)
        expect(editor.moveToFirstCharacterOfLine).toHaveBeenCalled()

    describe "the zb keybinding", ->
      beforeEach ->
        spyOn(editor, 'pixelPositionForScreenPosition').andReturn({top: 1000, left: 0})

      it "moves the screen to position cursor at the bottom of the window and leave cursor in the same column", ->
        keydown('z')
        keydown('b')
        expect(editor.setScrollTop).toHaveBeenCalledWith(860)
        expect(editor.moveToFirstCharacterOfLine).not.toHaveBeenCalled()

  describe "scrolling half screen keybindings", ->
    beforeEach ->
      text = ""
      for i in [1..80]
        text += "#{i}\n"
      editor.setText(text)

      spyOn(editor, 'setScrollTop')
      spyOn(editor, 'getFirstVisibleScreenRow').andReturn(40)
      spyOn(editor, 'getLastVisibleScreenRow').andReturn(60)
      spyOn(editor, 'getHeight').andReturn(400)
      spyOn(editor, 'getScrollTop').andReturn(600)

    describe "the ctrl-u keybinding", ->
      beforeEach ->
        spyOn(editor, 'setCursorScreenPosition')

      it "moves the screen down by half screen size and keeps cursor onscreen", ->
        keydown('u', ctrl: true)
        expect(editor.setScrollTop).toHaveBeenCalledWith(400)

    describe "the ctrl-d keybinding", ->
      beforeEach ->
        spyOn(editor, 'setCursorScreenPosition')

      it "moves the screen down by half screen size and keeps cursor onscreen", ->
        keydown('d', ctrl: true)
        expect(editor.setScrollTop).toHaveBeenCalledWith(800)
