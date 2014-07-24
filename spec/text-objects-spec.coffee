helpers = require './spec-helper'

describe "TextObjects", ->
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
      expect(editorView).not.toHaveClass('operator-pending-mode')
      expect(editorView).toHaveClass('command-mode')

    it "selects inside the current word in visual mode", ->
      keydown('v')
      keydown('i')
      keydown('w')

      expect(editor.getSelectedScreenRange()).toEqual [[0, 6], [0, 11]]

  describe "inside parentheses", ->
    insideParentheses = (keyAlias, keyOpts={}) ->
      describe "the 'i#{keyAlias}' text object", ->
        beforeEach ->
          editor.setText("( something in here and in (here) )")
          editor.setCursorScreenPosition([0, 9])

        it "applies operators inside the current word in operator-pending mode", ->
          keydown('d')
          keydown('i')
          keydown(keyAlias, keyOpts)
          expect(editor.getText()).toBe "()"
          expect(editor.getCursorScreenPosition()).toEqual [0, 1]
          expect(editorView).not.toHaveClass('operator-pending-mode')
          expect(editorView).toHaveClass('command-mode')

        it "applies operators inside the current word in operator-pending mode (second test)", ->
          editor.setCursorScreenPosition([0, 29])
          keydown('d')
          keydown('i')
          keydown(keyAlias, keyOpts)
          expect(editor.getText()).toBe "( something in here and in () )"
          expect(editor.getCursorScreenPosition()).toEqual [0, 28]
          expect(editorView).not.toHaveClass('operator-pending-mode')
          expect(editorView).toHaveClass('command-mode')

    insideParentheses('(')
    insideParentheses(')')
    insideParentheses('b')

  describe "inside curly brackets", ->
    insideCurlyBrackets = (keyAlias, keyOpts={}) ->
      describe "the 'i#{keyAlias}' text object", ->
        beforeEach ->
          editor.setText("{ something in here and in {here} }")
          editor.setCursorScreenPosition([0, 9])

        it "applies operators inside the current word in operator-pending mode", ->
          keydown('d')
          keydown('i')
          keydown(keyAlias, keyOpts)
          expect(editor.getText()).toBe "{}"
          expect(editor.getCursorScreenPosition()).toEqual [0, 1]
          expect(editorView).not.toHaveClass('operator-pending-mode')
          expect(editorView).toHaveClass('command-mode')

        it "applies operators inside the current word in operator-pending mode (second test)", ->
          editor.setCursorScreenPosition([0, 29])
          keydown('d')
          keydown('i')
          keydown(keyAlias, keyOpts)
          expect(editor.getText()).toBe "{ something in here and in {} }"
          expect(editor.getCursorScreenPosition()).toEqual [0, 28]
          expect(editorView).not.toHaveClass('operator-pending-mode')
          expect(editorView).toHaveClass('command-mode')

    insideCurlyBrackets('{')
    insideCurlyBrackets('}')
    insideCurlyBrackets('B', shift: true)

  describe "inside angle brackets", ->
    insideAngleBrackets = (keyAlias, keyOpts={}) ->
      describe "the 'i#{keyAlias}' text object", ->
        beforeEach ->
          editor.setText("< something in here and in <here> >")
          editor.setCursorScreenPosition([0, 9])

        it "applies operators inside the current word in operator-pending mode", ->
          keydown('d')
          keydown('i')
          keydown(keyAlias, keyOpts)
          expect(editor.getText()).toBe "<>"
          expect(editor.getCursorScreenPosition()).toEqual [0, 1]
          expect(editorView).not.toHaveClass('operator-pending-mode')
          expect(editorView).toHaveClass('command-mode')

        it "applies operators inside the current word in operator-pending mode (second test)", ->
          editor.setCursorScreenPosition([0, 29])
          keydown('d')
          keydown('i')
          keydown(keyAlias, keyOpts)
          expect(editor.getText()).toBe "< something in here and in <> >"
          expect(editor.getCursorScreenPosition()).toEqual [0, 28]
          expect(editorView).not.toHaveClass('operator-pending-mode')
          expect(editorView).toHaveClass('command-mode')

    insideAngleBrackets('<')
    insideAngleBrackets('>')

  describe "the 'i\'' text object", ->
    beforeEach ->
      editor.setText("' something in here and in 'here' '")
      editor.setCursorScreenPosition([0, 9])

    it "applies operators inside the current word in operator-pending mode", ->
      keydown('d')
      keydown('i')
      keydown('\'')
      expect(editor.getText()).toBe "''here' '"
      expect(editor.getCursorScreenPosition()).toEqual [0, 1]
      expect(editorView).not.toHaveClass('operator-pending-mode')
      expect(editorView).toHaveClass('command-mode')

    it "applies operators inside the current word in operator-pending mode (second test)", ->
      editor.setCursorScreenPosition([0, 29])
      keydown('d')
      keydown('i')
      keydown('\'')
      expect(editor.getText()).toBe "' something in here and in '' '"
      expect(editor.getCursorScreenPosition()).toEqual [0, 28]
      expect(editorView).not.toHaveClass('operator-pending-mode')
      expect(editorView).toHaveClass('command-mode')

  describe "the 'i\"' text object", ->
    beforeEach ->
      editor.setText("\" something in here and in \"here\" \"")
      editor.setCursorScreenPosition([0, 9])

    it "applies operators inside the current word in operator-pending mode", ->
      keydown('d')
      keydown('i')
      keydown('""')
      expect(editor.getText()).toBe '""here" "'
      expect(editor.getCursorScreenPosition()).toEqual [0, 1]
      expect(editorView).not.toHaveClass('operator-pending-mode')
      expect(editorView).toHaveClass('command-mode')

    it "applies operators inside the current word in operator-pending mode (second test)", ->
      editor.setCursorScreenPosition([0, 29])
      keydown('d')
      keydown('i')
      keydown('"')
      expect(editor.getText()).toBe "\" something in here and in \"\" \""
      expect(editor.getCursorScreenPosition()).toEqual [0, 28]
      expect(editorView).not.toHaveClass('operator-pending-mode')
      expect(editorView).toHaveClass('command-mode')
