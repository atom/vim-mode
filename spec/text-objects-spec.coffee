helpers = require './spec-helper'

describe "TextObjects", ->
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

  commandModeInputKeydown = (key, opts = {}) ->
    opts.element = editor.commandModeInputView.editor.find('input').get(0)
    opts.raw = true
    keydown(key, opts)

  describe "the 'iw' text object", ->
    beforeEach ->
      editor.setText("12345 abcde ABCDE")
      editor.setCursorScreenPosition([0, 9])

    it "applies operators inside the current word in operator-pending mode", ->
      keydown('d')
      keydown('i')
      keydown('w')

      expect(editor.getText()).toBe "12345  ABCDE"
      expect(editor.getCursorScreenPosition()).toEqual [0, 6]
      expect(vimState.getRegister('"').text).toBe "abcde"
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('command-mode')).toBe(true)

    it "selects inside the current word in visual mode", ->
      keydown('v')
      keydown('i')
      keydown('w')

      expect(editor.getSelectedScreenRange()).toEqual [[0, 6], [0, 11]]

    it "works with multiple cursors", ->
      editor.addCursorAtBufferPosition([0, 1])
      keydown("v")
      keydown("i")
      keydown("w")
      expect(editor.getSelectedBufferRanges()).toEqual [
        [[0, 6], [0, 11]]
        [[0, 0], [0, 5]]
      ]

  describe "the 'i(' text object", ->
    beforeEach ->
      editor.setText("( something in here and in (here) )")
      editor.setCursorScreenPosition([0, 9])

    it "applies operators inside the current word in operator-pending mode", ->
      keydown('d')
      keydown('i')
      keydown('(')
      expect(editor.getText()).toBe "()"
      expect(editor.getCursorScreenPosition()).toEqual [0, 1]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('command-mode')).toBe(true)

    it "applies operators inside the current word in operator-pending mode (second test)", ->
      editor.setCursorScreenPosition([0, 29])
      keydown('d')
      keydown('i')
      keydown('(')
      expect(editor.getText()).toBe "( something in here and in () )"
      expect(editor.getCursorScreenPosition()).toEqual [0, 28]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('command-mode')).toBe(true)

    it "works with multiple cursors", ->
      editor.setText("( a b ) cde ( f g h ) ijk")
      editor.setCursorBufferPosition([0, 2])
      editor.addCursorAtBufferPosition([0, 18])

      keydown("v")
      keydown("i")
      keydown("(")

      expect(editor.getSelectedBufferRanges()).toEqual [
        [[0, 1],  [0, 6]]
        [[0, 13], [0, 20]]
      ]

  describe "the 'i{' text object", ->
    beforeEach ->
      editor.setText("{ something in here and in {here} }")
      editor.setCursorScreenPosition([0, 9])

    it "applies operators inside the current word in operator-pending mode", ->
      keydown('d')
      keydown('i')
      keydown('{')
      expect(editor.getText()).toBe "{}"
      expect(editor.getCursorScreenPosition()).toEqual [0, 1]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('command-mode')).toBe(true)

    it "applies operators inside the current word in operator-pending mode (second test)", ->
      editor.setCursorScreenPosition([0, 29])
      keydown('d')
      keydown('i')
      keydown('{')
      expect(editor.getText()).toBe "{ something in here and in {} }"
      expect(editor.getCursorScreenPosition()).toEqual [0, 28]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('command-mode')).toBe(true)

  describe "the 'i<' text object", ->
    beforeEach ->
      editor.setText("< something in here and in <here> >")
      editor.setCursorScreenPosition([0, 9])

    it "applies operators inside the current word in operator-pending mode", ->
      keydown('d')
      keydown('i')
      keydown('<')
      expect(editor.getText()).toBe "<>"
      expect(editor.getCursorScreenPosition()).toEqual [0, 1]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('command-mode')).toBe(true)

    it "applies operators inside the current word in operator-pending mode (second test)", ->
      editor.setCursorScreenPosition([0, 29])
      keydown('d')
      keydown('i')
      keydown('<')
      expect(editor.getText()).toBe "< something in here and in <> >"
      expect(editor.getCursorScreenPosition()).toEqual [0, 28]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('command-mode')).toBe(true)

  describe "the 'it' text object", ->
    beforeEach ->
      editor.setText("<something>here</something><again>")
      editor.setCursorScreenPosition([0, 5])

    it "applies only if in the value of a tag", ->
      keydown('d')
      keydown('i')
      keydown('t')
      expect(editor.getText()).toBe "<something>here</something><again>"
      expect(editor.getCursorScreenPosition()).toEqual [0, 5]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('command-mode')).toBe(true)

    it "applies operators inside the current word in operator-pending mode", ->
      editor.setCursorScreenPosition([0, 13])
      keydown('d')
      keydown('i')
      keydown('t')
      expect(editor.getText()).toBe "<something></something><again>"
      expect(editor.getCursorScreenPosition()).toEqual [0, 11]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('command-mode')).toBe(true)

  describe "the 'i[' text object", ->
    beforeEach ->
      editor.setText("[ something in here and in [here] ]")
      editor.setCursorScreenPosition([0, 9])

    it "applies operators inside the current word in operator-pending mode", ->
      keydown('d')
      keydown('i')
      keydown('[')
      expect(editor.getText()).toBe "[]"
      expect(editor.getCursorScreenPosition()).toEqual [0, 1]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('command-mode')).toBe(true)

    it "applies operators inside the current word in operator-pending mode (second test)", ->
      editor.setCursorScreenPosition([0, 29])
      keydown('d')
      keydown('i')
      keydown('[')
      expect(editor.getText()).toBe "[ something in here and in [] ]"
      expect(editor.getCursorScreenPosition()).toEqual [0, 28]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('command-mode')).toBe(true)

  describe "the 'i\'' text object", ->
    beforeEach ->
      editor.setText("' something in here and in 'here' ' and over here")
      editor.setCursorScreenPosition([0, 9])

    it "applies operators inside the current string in operator-pending mode", ->
      keydown('d')
      keydown('i')
      keydown('\'')
      expect(editor.getText()).toBe "''here' ' and over here"
      expect(editor.getCursorScreenPosition()).toEqual [0, 1]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('command-mode')).toBe(true)

    it "applies operators inside the next string in operator-pending mode (if not in a string)", ->
      editor.setCursorScreenPosition([0, 29])
      keydown('d')
      keydown('i')
      keydown('\'')
      expect(editor.getText()).toBe "' something in here and in 'here'' and over here"
      expect(editor.getCursorScreenPosition()).toEqual [0, 33]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('command-mode')).toBe(true)

    it "makes no change if past the last string on a line", ->
      editor.setCursorScreenPosition([0, 39])
      keydown('d')
      keydown('i')
      keydown('\'')
      expect(editor.getText()).toBe "' something in here and in 'here' ' and over here"
      expect(editor.getCursorScreenPosition()).toEqual [0, 39]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('command-mode')).toBe(true)

  describe "the 'i\"' text object", ->
    beforeEach ->
      editor.setText("\" something in here and in \"here\" \" and over here")
      editor.setCursorScreenPosition([0, 9])

    it "applies operators inside the current string in operator-pending mode", ->
      keydown('d')
      keydown('i')
      keydown('"')
      expect(editor.getText()).toBe "\"\"here\" \" and over here"
      expect(editor.getCursorScreenPosition()).toEqual [0, 1]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('command-mode')).toBe(true)

    it "applies operators inside the next string in operator-pending mode (if not in a string)", ->
      editor.setCursorScreenPosition([0, 29])
      keydown('d')
      keydown('i')
      keydown('"')
      expect(editor.getText()).toBe "\" something in here and in \"here\"\" and over here"
      expect(editor.getCursorScreenPosition()).toEqual [0, 33]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('command-mode')).toBe(true)

    it "makes no change if past the last string on a line", ->
      editor.setCursorScreenPosition([0, 39])
      keydown('d')
      keydown('i')
      keydown('"')
      expect(editor.getText()).toBe "\" something in here and in \"here\" \" and over here"
      expect(editor.getCursorScreenPosition()).toEqual [0, 39]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)

  describe "the 'aw' text object", ->
    beforeEach ->
      editor.setText("12345 abcde ABCDE")
      editor.setCursorScreenPosition([0, 9])

    it "applies operators from the start of the current word to the start of the next word in operator-pending mode", ->
      keydown('d')
      keydown('a')
      keydown('w')

      expect(editor.getText()).toBe "12345 ABCDE"
      expect(editor.getCursorScreenPosition()).toEqual [0, 6]
      expect(vimState.getRegister('"').text).toBe "abcde "
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('command-mode')).toBe(true)

    it "selects from the start of the current word to the start of the next word in visual mode", ->
      keydown('v')
      keydown('a')
      keydown('w')

      expect(editor.getSelectedScreenRange()).toEqual [[0, 6], [0, 12]]

    it "doesn't span newlines", ->
      editor.setText("12345\nabcde ABCDE")
      editor.setCursorBufferPosition([0, 3])

      keydown("v")
      keydown("a")
      keydown("w")

      expect(editor.getSelectedBufferRanges()).toEqual [[[0, 0], [0, 5]]]

  describe "the 'a(' text object", ->
    beforeEach ->
      editor.setText("( something in here and in (here) )")
      editor.setCursorScreenPosition([0, 9])

    it "applies operators around the current parentheses in operator-pending mode", ->
      keydown('d')
      keydown('a')
      keydown('(')
      expect(editor.getText()).toBe ""
      expect(editor.getCursorScreenPosition()).toEqual [0, 0]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('command-mode')).toBe(true)

    it "applies operators around the current parentheses in operator-pending mode (second test)", ->
      editor.setCursorScreenPosition([0, 29])
      keydown('d')
      keydown('a')
      keydown('(')
      expect(editor.getText()).toBe "( something in here and in  )"
      expect(editor.getCursorScreenPosition()).toEqual [0, 27]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('command-mode')).toBe(true)

  describe "the 'a{' text object", ->
    beforeEach ->
      editor.setText("{ something in here and in {here} }")
      editor.setCursorScreenPosition([0, 9])

    it "applies operators around the current curly brackets in operator-pending mode", ->
      keydown('d')
      keydown('a')
      keydown('{')
      expect(editor.getText()).toBe ""
      expect(editor.getCursorScreenPosition()).toEqual [0, 0]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('command-mode')).toBe(true)

    it "applies operators around the current curly brackets in operator-pending mode (second test)", ->
      editor.setCursorScreenPosition([0, 29])
      keydown('d')
      keydown('a')
      keydown('{')
      expect(editor.getText()).toBe "{ something in here and in  }"
      expect(editor.getCursorScreenPosition()).toEqual [0, 27]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('command-mode')).toBe(true)

  describe "the 'a<' text object", ->
    beforeEach ->
      editor.setText("< something in here and in <here> >")
      editor.setCursorScreenPosition([0, 9])

    it "applies operators around the current angle brackets in operator-pending mode", ->
      keydown('d')
      keydown('a')
      keydown('<')
      expect(editor.getText()).toBe ""
      expect(editor.getCursorScreenPosition()).toEqual [0, 0]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('command-mode')).toBe(true)

    it "applies operators around the current angle brackets in operator-pending mode (second test)", ->
      editor.setCursorScreenPosition([0, 29])
      keydown('d')
      keydown('a')
      keydown('<')
      expect(editor.getText()).toBe "< something in here and in  >"
      expect(editor.getCursorScreenPosition()).toEqual [0, 27]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('command-mode')).toBe(true)

  describe "the 'a[' text object", ->
    beforeEach ->
      editor.setText("[ something in here and in [here] ]")
      editor.setCursorScreenPosition([0, 9])

    it "applies operators around the current square brackets in operator-pending mode", ->
      keydown('d')
      keydown('a')
      keydown('[')
      expect(editor.getText()).toBe ""
      expect(editor.getCursorScreenPosition()).toEqual [0, 0]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('command-mode')).toBe(true)

    it "applies operators around the current square brackets in operator-pending mode (second test)", ->
      editor.setCursorScreenPosition([0, 29])
      keydown('d')
      keydown('a')
      keydown('[')
      expect(editor.getText()).toBe "[ something in here and in  ]"
      expect(editor.getCursorScreenPosition()).toEqual [0, 27]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('command-mode')).toBe(true)

  describe "the 'a\'' text object", ->
    beforeEach ->
      editor.setText("' something in here and in 'here' '")
      editor.setCursorScreenPosition([0, 9])

    it "applies operators around the current single quotes in operator-pending mode", ->
      keydown('d')
      keydown('a')
      keydown('\'')
      expect(editor.getText()).toBe "here' '"
      expect(editor.getCursorScreenPosition()).toEqual [0, 0]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('command-mode')).toBe(true)

    it "applies operators around the current single quotes in operator-pending mode (second test)", ->
      editor.setCursorScreenPosition([0, 29])
      keydown('d')
      keydown('a')
      keydown('\'')
      expect(editor.getText()).toBe "' something in here and in 'here"
      expect(editor.getCursorScreenPosition()).toEqual [0, 31]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('command-mode')).toBe(true)

  describe "the 'a\"' text object", ->
    beforeEach ->
      editor.setText("\" something in here and in \"here\" \"")
      editor.setCursorScreenPosition([0, 9])

    it "applies operators around the current double quotes in operator-pending mode", ->
      keydown('d')
      keydown('a')
      keydown('""')
      expect(editor.getText()).toBe 'here" "'
      expect(editor.getCursorScreenPosition()).toEqual [0, 0]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('command-mode')).toBe(true)

    it "applies operators around the current double quotes in operator-pending mode (second test)", ->
      editor.setCursorScreenPosition([0, 29])
      keydown('d')
      keydown('a')
      keydown('"')
      expect(editor.getText()).toBe "\" something in here and in \"here"
      expect(editor.getCursorScreenPosition()).toEqual [0, 31]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('command-mode')).toBe(true)
