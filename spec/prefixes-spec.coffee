Keymap = require 'keymap'

helpers = require './spec-helper'

describe "Prefixes", ->
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

  describe "the Repeat prefix", ->
    it "repeats the following operation N times", ->
      editor.setText("12345")
      editor.setCursorScreenPosition([0,1])

      keydown('3', element: editor[0])
      keydown('x', element: editor[0])

      expect(editor.getText()).toBe '15'

      editor.setText("123456789abc")
      editor.setCursorScreenPosition([0,0])
      keydown('1', element: editor[0])
      keydown('0', element: editor[0])
      keydown('x', element: editor[0])

      expect(editor.getText()).toBe 'bc'

    it "repeats the following motion N times", ->
      editor.setText("one two three")
      editor.setCursorScreenPosition([0,0])

      keydown('d', element: editor[0])
      keydown('2', element: editor[0])
      keydown('w', element: editor[0])

      expect(editor.getText()).toBe 'three'
