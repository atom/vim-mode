$ = require 'jquery'

Keymap = require 'keymap'

helpers = require './spec-helper'

describe "Motions", ->
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

    editor.setText("12345\nabcde\nABCDE")
    editor.setCursorScreenPosition([1,1])

  afterEach ->
    window.keymap = originalKeymap

  describe "the h keybinding", ->
    it "moves the cursor left, but not to the previous line", ->
      keydown('h', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual([1,0])
      keydown('h', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual([1,0])

    it 'selects the character to the left', ->
      keydown('y', element: editor[0])
      keydown('h', element: editor[0])

      expect(vimState.getRegister('"').text).toBe "a"
      expect(editor.getCursorScreenPosition()).toEqual([1,0])

  describe "the j keybinding", ->
    it "moves the cursor down, but not to the end of the last line", ->
      keydown('j', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual([2,1])
      keydown('j', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual([2,1])

  describe "the k keybinding", ->
    it "moves the cursor up, but not to the beginning of the first line", ->
      keydown('k', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual([0,1])
      keydown('k', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual([0,1])

  describe "the l keybinding", ->
    it "moves the cursor right, but not to the next line", ->
      editor.setCursorScreenPosition([1,3])
      keydown('l', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual([1,4])
      keydown('l', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual([1,4])

  describe "the w keybinding", ->
    xit "moves the cursor to the beginning of the next word", ->
      editor.setText("ab cde1+- \n xyz\n\nzip")
      editor.setCursorScreenPosition([0,0])

      keydown('w', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual([0,3])

      keydown('w', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual([0,7])

      keydown('w', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual([1,1])

      keydown('w', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual([2,0])

      # FIXME: The definition of Cursor#getEndOfCurrentWordBufferPosition,
      # means that the end of the word can't be the current cursor
      # position (even though it is when you're cursor is on a new line).
      #
      # Therefore it picks the end of the next word here (which is [3,3])
      # to start looking for the next word, which is also the end of the
      # buffer so the cursor never advances.
      #
      # See atom/vim-mode#3
      keydown('w', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual([3,0])

      keydown('w', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual([3,2])

    it 'selects to the end of the current word', ->
      editor.setText("ab  cde1+- \n xyz\n\nzip")
      editor.setCursorScreenPosition([0,1])

      keydown('y', element: editor[0])
      keydown('w', element: editor[0])

      expect(vimState.getRegister('"').text).toBe "b  "

      editor.setCursorScreenPosition([0,2])

      keydown('y', element: editor[0])
      keydown('w', element: editor[0])

      expect(vimState.getRegister('"').text).toBe "  "

  describe "the e keybinding", ->
    it "moves the cursor to the end of the current word", ->
      editor.setText("ab cde1+- \n xyz\n\nzip")
      editor.setCursorScreenPosition([0, 0])

      keydown('e', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual [0, 1]

      keydown('e', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual [0, 6]

      keydown('e', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual [0, 8]

      keydown('e', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual [1, 3]

      # INCOMPATIBILITY: vim doesn't stop at [2, 0] it advances immediately
      # to [3, 2]
      keydown('e', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual [2, 0]

      keydown('e', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual [3, 2]

    it 'selects to the end of the current word', ->
      editor.setText("ab  cde1+- \n xyz\n\nzip")
      editor.setCursorScreenPosition([0, 0])

      keydown('y', element: editor[0])
      keydown('e', element: editor[0])

      expect(vimState.getRegister('"').text).toBe "ab"

      editor.setCursorScreenPosition([0,2])

      keydown('y', element: editor[0])
      keydown('e', element: editor[0])

      expect(vimState.getRegister('"').text).toBe "  cde1"

  describe "the } keybinding", ->
    beforeEach ->
      editor.setText("abcde\n\nfghij\nhijk\n  xyz  \n\nzip\n\n  \nthe end")
      editor.setCursorScreenPosition([0,0])

    it "moves the cursor to the beginning of the paragraph", ->
      keydown('}', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual [1,0]

      keydown('}', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual [5,0]

      keydown('}', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual [7,0]

      keydown('}', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual [9,6]

    it 'selects to the end of the current word', ->
      keydown('y', element: editor[0])
      keydown('}', element: editor[0])

      expect(vimState.getRegister('"').text).toBe "abcde\n"

  describe "the b keybinding", ->
    xit "moves the cursor to the beginning of the previous word", ->
      editor.setText(" ab cde1+- \n xyz\n\nzip }\n last")
      editor.setCursorScreenPosition [4,1]

      keydown('b', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual [3,4]

      keydown('b', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual [3,0]

      keydown('b', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual [2,0]

      keydown('b', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual [1,1]

      keydown('b', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual [0,8]

      keydown('b', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual [0,4]

      keydown('b', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual [0,1]

      # FIXME: The definition of Cursor#getMovePreviousWordBoundaryBufferPosition
      # will always stop on the last word in the buffer. The question is should
      # we change this behavior.
      #
      # See atom/vim-mode#3
      keydown('b', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual [0,0]

      keydown('b', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual [0,0]

    it 'selects to the beginning of the current word', ->
      editor.setText("ab  cde1+- \n xyz\n\nzip")
      editor.setCursorScreenPosition([0,2])

      keydown('y', element: editor[0])
      keydown('b', element: editor[0])

      expect(vimState.getRegister('"').text).toBe "ab"
      expect(editor.getCursorScreenPosition()).toEqual [0,0]

      editor.setCursorScreenPosition([0,4])

      keydown('y', element: editor[0])
      keydown('b', element: editor[0])

      expect(vimState.getRegister('"').text).toBe "ab  "
      expect(editor.getCursorScreenPosition()).toEqual [0,0]

  describe "the ^ keybinding", ->
    beforeEach ->
      editor.setText("  abcde")
      editor.setCursorScreenPosition([0,4])

    it 'moves the cursor to the beginning of the line', ->
      keydown('^', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual [0,2]

    it 'selects to the beginning of the lines', ->
      keydown('d', element: editor[0])
      keydown('^', element: editor[0])

      expect(editor.getText()).toBe '  cde'
      expect(editor.getCursorScreenPosition()).toEqual [0,2]

  describe "the $ keybinding", ->
    beforeEach ->
      editor.setText("  abcde\n")
      editor.setCursorScreenPosition([0,4])

    # FIXME: See atom/vim-mode#2
    xit 'moves the cursor to the end of the line', ->
      keydown('$', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual [0,6]

    it 'selects to the beginning of the lines', ->
      keydown('d', element: editor[0])
      keydown('$', element: editor[0])

      expect(editor.getText()).toBe "  ab\n"
      # FIXME: See atom/vim-mode#2
      #expect(editor.getCursorScreenPosition()).toEqual [0,3]

  # FIXME: this doesn't work as we can't determine if this is a motion
  # or part of a repeat prefix.
  xdescribe "the 0 keybinding", ->
    beforeEach ->
      editor.setText("  a\n")
      editor.setCursorScreenPosition([0,2])

    it 'moves the cursor to the beginning of the line', ->
      keydown('0', element: editor[0])
      expect(editor.getCursorScreenPosition()).toEqual [0,0]

  describe "the gg keybinding", ->
    beforeEach ->
      editor.setText(" 1abc\n2\n3\n")
      editor.setCursorScreenPosition([0,2])

    it 'moves the cursor to the beginning of the first line', ->
      keydown('g', element: editor[0])
      keydown('g', element: editor[0])

      expect(editor.getCursorScreenPosition()).toEqual [0, 1]

  describe "the G keybinding", ->
    beforeEach ->
      editor.setText("1\n    2\n 3abc\n ")
      editor.setCursorScreenPosition([0,2])

    it 'moves the cursor to the last line after whitespace', ->
      keydown('G', shift: true, element: editor[0])

      expect(editor.getCursorScreenPosition()).toEqual [3, 1]

    it 'moves the cursor to a specified line', ->
      keydown('2', element: editor[0])
      keydown('G', shift: true, element: editor[0])

      expect(editor.getCursorScreenPosition()).toEqual [1, 4]
