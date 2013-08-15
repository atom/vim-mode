helpers = require './spec-helper'

describe "Prefixes", ->
  [editor, vimState] = []

  beforeEach ->
    vimMode = atom.loadPackage('vim-mode')
    vimMode.activateResources()

    editor = helpers.cacheEditor(editor)

    vimState = editor.vimState
    vimState.activateCommandMode()
    vimState.resetCommandMode()

  keydown = (key, options={}) ->
    options.element ?= editor[0]
    helpers.keydown(key, options)

  describe "the Repeat prefix", ->
    it "repeats the following operation N times", ->
      editor.setText("12345")
      editor.setCursorScreenPosition([0, 1])

      keydown('3')
      keydown('x')

      expect(editor.getText()).toBe '15'

      editor.setText("123456789abc")
      editor.setCursorScreenPosition([0, 0])
      keydown('1')
      keydown('0')
      keydown('x')

      expect(editor.getText()).toBe 'bc'

    it "repeats the following motion N times", ->
      editor.setText("one two three")
      editor.setCursorScreenPosition([0, 0])

      keydown('d')
      keydown('2')
      keydown('w')

      expect(editor.getText()).toBe 'three'
