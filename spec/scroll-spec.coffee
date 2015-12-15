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
      vimState.activateNormalMode()
      vimState.resetNormalMode()
      jasmine.attachToDOM(element)

  keydown = (key, options={}) ->
    options.element ?= editorElement
    helpers.keydown(key, options)

  describe "scrolling keybindings", ->
    beforeEach ->
      editor.setText """
        100
        200
        300
        400
        500
        600
        700
        800
        900
        1000
      """

      editor.setCursorBufferPosition([1, 2])
      editorElement.setHeight(editorElement.getHeight() * 4 / 10)
      expect(editor.getVisibleRowRange()).toEqual [0, 4]

    describe "the ctrl-e and ctrl-y keybindings", ->
      it "moves the screen up and down by one and keeps cursor onscreen", ->
        keydown('e', ctrl: true)
        expect(editor.getFirstVisibleScreenRow()).toBe 1
        expect(editor.getLastVisibleScreenRow()).toBe 5
        expect(editor.getCursorScreenPosition()).toEqual [2, 2]

        keydown('2')
        keydown('e', ctrl: true)
        expect(editor.getFirstVisibleScreenRow()).toBe 3
        expect(editor.getLastVisibleScreenRow()).toBe 7
        expect(editor.getCursorScreenPosition()).toEqual [4, 2]

        keydown('2')
        keydown('y', ctrl: true)
        expect(editor.getFirstVisibleScreenRow()).toBe 1
        expect(editor.getLastVisibleScreenRow()).toBe 5
        expect(editor.getCursorScreenPosition()).toEqual [2, 2]

  describe "scroll cursor keybindings", ->
    beforeEach ->
      text = ""
      for i in [1..200]
        text += "#{i}\n"
      editor.setText(text)

      spyOn(editor, 'moveToFirstCharacterOfLine')

      spyOn(editorElement, 'setScrollTop')
      editorElement.style.lineHeight = "20px"
      editorElement.component.sampleFontStyling()
      editorElement.setHeight(200)
      spyOn(editorElement, 'getFirstVisibleScreenRow').andReturn(90)
      spyOn(editorElement, 'getLastVisibleScreenRow').andReturn(110)

    describe "the z<CR> keybinding", ->
      keydownCodeForEnter = '\r'

      beforeEach ->
        spyOn(editorElement, 'pixelPositionForScreenPosition').andReturn({top: 1000, left: 0})

      it "moves the screen to position cursor at the top of the window and moves cursor to first non-blank in the line", ->
        keydown('z')
        keydown(keydownCodeForEnter)
        expect(editorElement.setScrollTop).toHaveBeenCalledWith(960)
        expect(editor.moveToFirstCharacterOfLine).toHaveBeenCalled()

    describe "the zt keybinding", ->
      beforeEach ->
        spyOn(editorElement, 'pixelPositionForScreenPosition').andReturn({top: 1000, left: 0})

      it "moves the screen to position cursor at the top of the window and leave cursor in the same column", ->
        keydown('z')
        keydown('t')
        expect(editorElement.setScrollTop).toHaveBeenCalledWith(960)
        expect(editor.moveToFirstCharacterOfLine).not.toHaveBeenCalled()

    describe "the z. keybinding", ->
      beforeEach ->
        spyOn(editorElement, 'pixelPositionForScreenPosition').andReturn({top: 1000, left: 0})

      it "moves the screen to position cursor at the center of the window and moves cursor to first non-blank in the line", ->
        keydown('z')
        keydown('.')
        expect(editorElement.setScrollTop).toHaveBeenCalledWith(900)
        expect(editor.moveToFirstCharacterOfLine).toHaveBeenCalled()

    describe "the zz keybinding", ->
      beforeEach ->
        spyOn(editorElement, 'pixelPositionForScreenPosition').andReturn({top: 1000, left: 0})

      it "moves the screen to position cursor at the center of the window and leave cursor in the same column", ->
        keydown('z')
        keydown('z')
        expect(editorElement.setScrollTop).toHaveBeenCalledWith(900)
        expect(editor.moveToFirstCharacterOfLine).not.toHaveBeenCalled()

    describe "the z- keybinding", ->
      beforeEach ->
        spyOn(editorElement, 'pixelPositionForScreenPosition').andReturn({top: 1000, left: 0})

      it "moves the screen to position cursor at the bottom of the window and moves cursor to first non-blank in the line", ->
        keydown('z')
        keydown('-')
        expect(editorElement.setScrollTop).toHaveBeenCalledWith(860)
        expect(editor.moveToFirstCharacterOfLine).toHaveBeenCalled()

    describe "the zb keybinding", ->
      beforeEach ->
        spyOn(editorElement, 'pixelPositionForScreenPosition').andReturn({top: 1000, left: 0})

      it "moves the screen to position cursor at the bottom of the window and leave cursor in the same column", ->
        keydown('z')
        keydown('b')
        expect(editorElement.setScrollTop).toHaveBeenCalledWith(860)
        expect(editor.moveToFirstCharacterOfLine).not.toHaveBeenCalled()

  describe "horizontal scroll cursor keybindings", ->
    beforeEach ->
      editorElement.setWidth(600)
      editorElement.setHeight(600)
      editorElement.style.lineHeight = "10px"
      editorElement.style.font = "16px monospace"
      atom.views.performDocumentPoll()
      text = ""
      for i in [100..199]
        text += "#{i} "
      editor.setText(text)
      editor.setCursorBufferPosition([0, 0])

    describe "the zs keybinding", ->
      zsPos = (pos) ->
        editor.setCursorBufferPosition([0, pos])
        keydown('z')
        keydown('s')
        editorElement.getScrollLeft()

      startPosition = NaN

      beforeEach ->
        startPosition = editorElement.getScrollLeft()

      it "does nothing near the start of the line", ->
        pos1 = zsPos(1)
        expect(pos1).toEqual(startPosition)

      it "moves the cursor the nearest it can to the left edge of the editor", ->
        pos10 = zsPos(10)
        expect(pos10).toBeGreaterThan(startPosition)

        pos11 = zsPos(11)
        expect(pos11 - pos10).toEqual(10)

      it "does nothing near the end of the line", ->
        posEnd = zsPos(399)
        expect(editor.getCursorBufferPosition()).toEqual [0, 399]

        pos390 = zsPos(390)
        expect(pos390).toEqual(posEnd)
        expect(editor.getCursorBufferPosition()).toEqual [0, 390]

        pos340 = zsPos(340)
        expect(pos340).toBeLessThan(posEnd)
        pos342 = zsPos(342)
        expect(pos342 - pos340).toEqual(19)

      it "does nothing if all lines are short", ->
        editor.setText('short')
        startPosition = editorElement.getScrollLeft()
        pos1 = zsPos(1)
        expect(pos1).toEqual(startPosition)
        expect(editor.getCursorBufferPosition()).toEqual [0, 1]
        pos10 = zsPos(10)
        expect(pos10).toEqual(startPosition)
        expect(editor.getCursorBufferPosition()).toEqual [0, 4]


    describe "the ze keybinding", ->
      zePos = (pos) ->
        editor.setCursorBufferPosition([0, pos])
        keydown('z')
        keydown('e')
        editorElement.getScrollLeft()

      startPosition = NaN

      beforeEach ->
        startPosition = editorElement.getScrollLeft()

      it "does nothing near the start of the line", ->
        pos1 = zePos(1)
        expect(pos1).toEqual(startPosition)

        pos40 = zePos(40)
        expect(pos40).toEqual(startPosition)

      it "moves the cursor the nearest it can to the right edge of the editor", ->
        pos110 = zePos(110)
        expect(pos110).toBeGreaterThan(startPosition)

        pos109 = zePos(109)
        expect(pos110 - pos109).toEqual(10)

      it "does nothing when very near the end of the line", ->
        posEnd = zePos(399)
        expect(editor.getCursorBufferPosition()).toEqual [0, 399]

        pos397 = zePos(397)
        expect(pos397).toEqual(posEnd)
        expect(editor.getCursorBufferPosition()).toEqual [0, 397]

        pos380 = zePos(380)
        expect(pos380).toBeLessThan(posEnd)

        pos382 = zePos(382)
        expect(pos382 - pos380).toEqual(19)

      it "does nothing if all lines are short", ->
        editor.setText('short')
        startPosition = editorElement.getScrollLeft()
        pos1 = zePos(1)
        expect(pos1).toEqual(startPosition)
        expect(editor.getCursorBufferPosition()).toEqual [0, 1]
        pos10 = zePos(10)
        expect(pos10).toEqual(startPosition)
        expect(editor.getCursorBufferPosition()).toEqual [0, 4]
