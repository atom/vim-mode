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
      vimState.activateNormalMode()
      vimState.resetNormalMode()

  keydown = (key, options={}) ->
    options.element ?= editorElement
    helpers.keydown(key, options)

  describe "Text Object commands in normal mode not preceded by an operator", ->
    beforeEach ->
      vimState.activateNormalMode()

    it "selects the appropriate text", ->
      editor.setText("<html> text </html>")
      editor.setCursorScreenPosition([0, 7])
      # Users could dispatch it via the command palette
      atom.commands.dispatch(editorElement, "vim-mode:select-inside-tags")
      expect(editor.getSelectedScreenRange()).toEqual [[0, 6], [0, 12]]

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
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "selects inside the current word in visual mode", ->
      keydown('v')
      keydown('i')
      keydown('w')

      expect(editor.getSelectedScreenRange()).toEqual [[0, 6], [0, 11]]

    it "expands an existing selection in visual mode", ->
      keydown('v')
      keydown('l')
      keydown('l')
      keydown('l')
      keydown('i')
      keydown('w')

      expect(editor.getSelectedScreenRange()).toEqual [[0, 9], [0, 17]]

    it "works with multiple cursors", ->
      editor.addCursorAtBufferPosition([0, 1])
      keydown("v")
      keydown("i")
      keydown("w")
      expect(editor.getSelectedBufferRanges()).toEqual [
        [[0, 6], [0, 11]]
        [[0, 0], [0, 5]]
      ]

  describe "the 'iW' text object", ->
    beforeEach ->
      editor.setText("12(45 ab'de ABCDE")
      editor.setCursorScreenPosition([0, 9])

    it "applies operators inside the current whole word in operator-pending mode", ->
      keydown('d')
      keydown('i')
      keydown('W', shift: true)

      expect(editor.getText()).toBe "12(45  ABCDE"
      expect(editor.getCursorScreenPosition()).toEqual [0, 6]
      expect(vimState.getRegister('"').text).toBe "ab'de"
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "selects inside the current whole word in visual mode", ->
      keydown('v')
      keydown('i')
      keydown('W', shift: true)

      expect(editor.getSelectedScreenRange()).toEqual [[0, 6], [0, 11]]

    it "expands an existing selection in visual mode", ->
      keydown('v')
      keydown('l')
      keydown('l')
      keydown('l')
      keydown('i')
      keydown('W', shift: true)

      expect(editor.getSelectedScreenRange()).toEqual [[0, 9], [0, 17]]

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
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "applies operators inside the current word in operator-pending mode (second test)", ->
      editor.setCursorScreenPosition([0, 29])
      keydown('d')
      keydown('i')
      keydown('(')
      expect(editor.getText()).toBe "( something in here and in () )"
      expect(editor.getCursorScreenPosition()).toEqual [0, 28]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

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

    it "expands an existing selection in visual mode", ->
      editor.setCursorScreenPosition([0, 25])
      keydown('v')
      keydown('l')
      keydown('l')
      keydown('l')
      keydown('l')
      keydown('i')
      keydown('(')

      expect(editor.getSelectedScreenRange()).toEqual [[0, 25], [0, 32]]

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
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "applies operators inside the current word in operator-pending mode (second test)", ->
      editor.setCursorScreenPosition([0, 29])
      keydown('d')
      keydown('i')
      keydown('{')
      expect(editor.getText()).toBe "{ something in here and in {} }"
      expect(editor.getCursorScreenPosition()).toEqual [0, 28]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "expands an existing selection in visual mode", ->
      editor.setCursorScreenPosition([0, 25])
      keydown('v')
      keydown('l')
      keydown('l')
      keydown('l')
      keydown('l')
      keydown('i')
      keydown('{')

      expect(editor.getSelectedScreenRange()).toEqual [[0, 25], [0, 32]]

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
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "applies operators inside the current word in operator-pending mode (second test)", ->
      editor.setCursorScreenPosition([0, 29])
      keydown('d')
      keydown('i')
      keydown('<')
      expect(editor.getText()).toBe "< something in here and in <> >"
      expect(editor.getCursorScreenPosition()).toEqual [0, 28]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "expands an existing selection in visual mode", ->
      editor.setCursorScreenPosition([0, 25])
      keydown('v')
      keydown('l')
      keydown('l')
      keydown('l')
      keydown('l')
      keydown('i')
      keydown('<')

      expect(editor.getSelectedScreenRange()).toEqual [[0, 25], [0, 32]]

  expectYankResult = (editorText, cursorPosition, result, {inner}) ->
    editor.setText(editorText)
    editor.setCursorBufferPosition(cursorPosition)
    keydown('y')
    if inner
      keydown('i')
    else
      keydown('a')
    keydown('t')
    expect(vimState.getRegister('"').text).toBe(result)

  describe "the 'it' text object", ->

    describe 'applies the operator in operator-pending-mode', ->

      beforeEach ->
        vimState.setRegister('"', {text: ''})

      it 'inside the tags', ->
        expectYankResult('<aa>bbb</aa>', [0, 0], 'bbb', inner: true)

      it 'not inside the tags if the cursor if after the tags', ->
        expectYankResult('<aa>bbb</aa> ', [0, 12], '', inner: true)

      it 'inside the first pair of tags if the cursor is before the tags', ->
        expectYankResult('  <aa>bbb</aa>  <aa>ccc</aa>', [0, 0], 'bbb', inner: true)

      it 'inside the first pair of tags if the cursor is inside the tags', ->
        expectYankResult('  <aa>bbb</aa>  <aa>ccc</aa>', [0, 10], 'bbb', inner: true)

      it 'inside the second pair of tags if the cursor is inside the second pair of tags', ->
        expectYankResult('  <aa>bbb</aa>  <aa>ccc</aa>', [0, 16], 'ccc', inner: true)

      it 'inside the outer pair of tags', ->
        expectYankResult('<aa> <bb>ccc</bb></aa>', [0, 4], ' <bb>ccc</bb>', inner: true)

      it 'inside the inner pair of tags', ->
        expectYankResult('<aa> <bb>ccc</bb></aa>', [0, 5], 'ccc', inner: true)

      it 'inside multiline tags when the cursor is at the start of the opening tag', ->
        expectYankResult('<aa>\nbb\n</aa>', [0, 0], '\nbb\n', inner: true)

      it 'inside multiline tags when the cursor is inside the opening tag', ->
        expectYankResult('<a>\ntext\n</a>', [0, 2], '\ntext\n', inner: true)

      it 'inside multiline tags when the cursor is on the same line as the opening tag', ->
        expectYankResult(' <aa>\nbb\n</aa>' , [0, 0], '\nbb\n', inner: true)

      it 'inside multiline tags when the cursor is on a line between the opening/closing tag', ->
        expectYankResult('<aa>\nbb\n</aa>' , [1, 0], '\nbb\n', inner: true)

      it 'inside multiline tags when the cursor is on the closing tag', ->
        expectYankResult('<aa>\nbb\n</aa>' , [2, 0], '\nbb\n', inner: true)

      it 'inside the outer multiline tags when the cursor is after inner the tags', ->
        expectYankResult('<aa>\n<bb></bb> \n</aa>' , [1, 15], '\n<bb></bb> \n', inner: true)

      it 'ignores the unclosed inner tag', ->
        expectYankResult('<aa>\n<bb>\n<c></c>\n</aa>' , [1, 0], '\n<bb>\n<c></c>\n', inner: true)

      it 'still ignores the unclosed tag with the cursor inside it', ->
        expectYankResult('<a>\n<c>text</c>' , [0, 1], '', inner: true)

      it 'ignores the last closing tag and the inner unclosed tag', ->
        expectYankResult('<a>\ntext\n<b></a></c>' , [1, 0], '\ntext\n<b>', inner: true)

    it 'selects inside the tags', ->
      editor.setText('<aa>bbb</aa>')
      editor.setCursorBufferPosition([0, 0])
      keydown('v')
      keydown('i')
      keydown('t')
      expect(editor.getSelectedScreenRange()).toEqual [[0, 4], [0, 7]]

  describe "the 'at' text object", ->

    describe 'applies the operator in operator-pending-mode', ->

      beforeEach ->
        vimState.setRegister('"', {text: ''})

      it 'around the tags', ->
        expectYankResult('<aa>bbb</aa>', [0, 0], '<aa>bbb</aa>', inner: false)

      it 'not around the tags if the cursor if after the tags', ->
        expectYankResult('<aa>bbb</aa> ', [0, 12], '', inner: false)

      it 'around the first pair of tags if the cursor is before the tags', ->
        expectYankResult('  <aa>bbb</aa>  <aa>ccc</aa>', [0, 0], '<aa>bbb</aa>', inner: false)

      it 'around the first pair of tags if the cursor is inside the tags', ->
        expectYankResult('  <aa>bbb</aa>  <aa>ccc</aa>', [0, 10], '<aa>bbb</aa>', inner: false)

      it 'around the second pair of tags if the cursor is inside the second pair of tags', ->
        expectYankResult('  <aa>bbb</aa>  <aa>ccc</aa>', [0, 16], '<aa>ccc</aa>', inner: false)

      it 'around the outer pair of tags', ->
        expectYankResult('<aa> <bb>ccc</bb></aa>', [0, 4], '<aa> <bb>ccc</bb></aa>', inner: false)

      it 'around the inner pair of tags', ->
        expectYankResult('<aa> <bb>ccc</bb></aa>', [0, 5], '<bb>ccc</bb>', inner: false)

      it 'around multiline tags when the cursor is at the start of the opening tag', ->
        expectYankResult('<aa>\nbb\n</aa>', [0, 0], '<aa>\nbb\n</aa>', inner: false)

      it 'around multiline tags when the cursor is inside the opening tag', ->
        expectYankResult('<a>\ntext\n</a>', [0, 2], '<a>\ntext\n</a>', inner: false)

      it 'around multiline tags when the cursor is on the same line as the opening tag', ->
        expectYankResult(' <aa>\nbb\n</aa>' , [0, 0], '<aa>\nbb\n</aa>', inner: false)

      it 'around multiline tags when the cursor is on a line between the opening/closing tag', ->
        expectYankResult('<aa>\nbb\n</aa>' , [1, 0], '<aa>\nbb\n</aa>', inner: false)

      it 'around multiline tags when the cursor is on the closing tag', ->
        expectYankResult('<aa>\nbb\n</aa>' , [2, 0], '<aa>\nbb\n</aa>', inner: false)

      it 'around the outer multiline tags when the cursor is after inner the tags', ->
        expectYankResult('<aa>\n<bb></bb> \n</aa>' , [1, 15], '<aa>\n<bb></bb> \n</aa>', inner: false)

      it 'around the outer tags, ignoring the unclosed inner tag', ->
        expectYankResult('<aa>\n<bb>\n<c></c>\n</aa>' , [1, 0], '<aa>\n<bb>\n<c></c>\n</aa>', inner: false)

      it 'ignores the unclosed tag with the cursor inside it', ->
        expectYankResult('<a>\n<c>text</c>' , [0, 1], '', inner: false)

      it 'around the <a> tag, ignoring the last closing tag and the inner unclosed tag', ->
        expectYankResult('<a>\ntext\n<b></a></c>' , [1, 0], '<a>\ntext\n<b></a>', inner: false)

    it 'selects around the tags', ->
      editor.setText('<aa>bbb</aa>')
      editor.setCursorBufferPosition([0, 0])
      keydown('v')
      keydown('i')
      keydown('t')
      expect(editor.getSelectedScreenRange()).toEqual [[0, 4], [0, 7]]

    it "does not expands an existing selection in visual mode", ->
      editor.setText('text <a>innerTag</a>')

      editor.setCursorScreenPosition([0, 0])
      keydown('v')
      keydown('6')
      keydown('l')
      expect(editor.getSelectedScreenRange()).toEqual [[0, 0], [0, 7]]

      keydown('i')
      keydown('t')
      expect(editor.getSelectedScreenRange()).toEqual [[0, 8], [0, 16]]

  describe "the 'ip' text object", ->
    beforeEach ->
      editor.setText("\nParagraph-1\nParagraph-1\nParagraph-1\n\n")
      editor.setCursorBufferPosition([2, 2])

    it "applies operators inside the current paragraph in operator-pending mode", ->
      keydown('y')
      keydown('i')
      keydown('p')

      expect(editor.getText()).toBe "\nParagraph-1\nParagraph-1\nParagraph-1\n\n"
      expect(editor.getCursorScreenPosition()).toEqual [1, 0]
      expect(vimState.getRegister('"').text).toBe "Paragraph-1\nParagraph-1\nParagraph-1\n"
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "selects inside the current paragraph in visual mode", ->
      keydown('v')
      keydown('i')
      keydown('p')

      expect(editor.getSelectedScreenRange()).toEqual [[1, 0], [4, 0]]

    it "selects between paragraphs in visual mode if invoked on a empty line", ->
      editor.setText("text\n\n\n\ntext\n")
      editor.setCursorBufferPosition([1, 0])

      keydown('v')
      keydown('i')
      keydown('p')

      expect(editor.getSelectedScreenRange()).toEqual [[1, 0], [4, 0]]

    it "selects all the lines", ->
      editor.setText("text\ntext\ntext\n")
      editor.setCursorBufferPosition([0, 0])

      keydown('v')
      keydown('i')
      keydown('p')

      expect(editor.getSelectedScreenRange()).toEqual [[0, 0], [3, 0]]

    it "expands an existing selection in visual mode", ->
      editor.setText("\nParagraph-1\nParagraph-1\nParagraph-1\n\n\nParagraph-2\nParagraph-2\nParagraph-2\n")
      editor.setCursorBufferPosition([2, 2])

      keydown('v')
      keydown('i')
      keydown('p')

      keydown('j')
      keydown('j')
      keydown('j')
      keydown('i')
      keydown('p')

      expect(editor.getSelectedScreenRange()).toEqual [[1, 0], [9, 0]]

  describe "the 'ap' text object", ->
    beforeEach ->
      editor.setText("text\n\nParagraph-1\nParagraph-1\nParagraph-1\n\n\nmoretext")
      editor.setCursorScreenPosition([3, 2])

    it "applies operators around the current paragraph in operator-pending mode", ->
      keydown('y')
      keydown('a')
      keydown('p')

      expect(editor.getText()).toBe "text\n\nParagraph-1\nParagraph-1\nParagraph-1\n\n\nmoretext"
      expect(editor.getCursorScreenPosition()).toEqual [2, 0]
      expect(vimState.getRegister('"').text).toBe "Paragraph-1\nParagraph-1\nParagraph-1\n\n\n"
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "selects around the current paragraph in visual mode", ->
      keydown('v')
      keydown('a')
      keydown('p')

      expect(editor.getSelectedScreenRange()).toEqual [[2, 0], [7, 0]]

    it "applies operators around the next paragraph in operator-pending mode when started from a blank/only-whitespace line", ->
      editor.setText("text\n\n\n\nParagraph-1\nParagraph-1\nParagraph-1\n\n\nmoretext")
      editor.setCursorBufferPosition([1, 0])

      keydown('y')
      keydown('a')
      keydown('p')

      expect(editor.getText()).toBe "text\n\n\n\nParagraph-1\nParagraph-1\nParagraph-1\n\n\nmoretext"
      expect(editor.getCursorScreenPosition()).toEqual [1, 0]
      expect(vimState.getRegister('"').text).toBe "\n\n\nParagraph-1\nParagraph-1\nParagraph-1\n"
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "selects around the next paragraph in visual mode when started from a blank/only-whitespace line", ->
      editor.setText("text\n\n\n\nparagraph-1\nparagraph-1\nparagraph-1\n\n\nmoretext")
      editor.setCursorBufferPosition([1, 0])

      keydown('v')
      keydown('a')
      keydown('p')

      expect(editor.getSelectedScreenRange()).toEqual [[1, 0], [7, 0]]

    it "expands an existing selection in visual mode", ->
      editor.setText("text\n\n\n\nparagraph-1\nparagraph-1\nparagraph-1\n\n\n\nparagraph-2\nparagraph-2\nparagraph-2\n\n\nmoretext")
      editor.setCursorBufferPosition([5, 0])

      keydown('v')
      keydown('a')
      keydown('p')

      keydown('j')
      keydown('j')
      keydown('j')
      keydown('i')
      keydown('p')

      expect(editor.getSelectedScreenRange()).toEqual [[4, 0], [13, 0]]

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
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "applies operators inside the current word in operator-pending mode (second test)", ->
      editor.setCursorScreenPosition([0, 29])
      keydown('d')
      keydown('i')
      keydown('[')
      expect(editor.getText()).toBe "[ something in here and in [] ]"
      expect(editor.getCursorScreenPosition()).toEqual [0, 28]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "expands an existing selection in visual mode", ->
      editor.setCursorScreenPosition([0, 25])
      keydown('v')
      keydown('l')
      keydown('l')
      keydown('l')
      keydown('l')
      keydown('i')
      keydown('[')

      expect(editor.getSelectedScreenRange()).toEqual [[0, 25], [0, 32]]

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
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "applies operators inside the next string in operator-pending mode (if not in a string)", ->
      editor.setCursorScreenPosition([0, 29])
      keydown('d')
      keydown('i')
      keydown('\'')
      expect(editor.getText()).toBe "' something in here and in 'here'' and over here"
      expect(editor.getCursorScreenPosition()).toEqual [0, 33]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "makes no change if past the last string on a line", ->
      editor.setCursorScreenPosition([0, 39])
      keydown('d')
      keydown('i')
      keydown('\'')
      expect(editor.getText()).toBe "' something in here and in 'here' ' and over here"
      expect(editor.getCursorScreenPosition()).toEqual [0, 39]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "expands an existing selection in visual mode", ->
      editor.setCursorScreenPosition([0, 25])
      keydown('v')
      keydown('l')
      keydown('l')
      keydown('l')
      keydown('l')
      keydown('i')
      keydown('\'')

      expect(editor.getSelectedScreenRange()).toEqual [[0, 25], [0, 34]]

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
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "applies operators inside the next string in operator-pending mode (if not in a string)", ->
      editor.setCursorScreenPosition([0, 29])
      keydown('d')
      keydown('i')
      keydown('"')
      expect(editor.getText()).toBe "\" something in here and in \"here\"\" and over here"
      expect(editor.getCursorScreenPosition()).toEqual [0, 33]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "makes no change if past the last string on a line", ->
      editor.setCursorScreenPosition([0, 39])
      keydown('d')
      keydown('i')
      keydown('"')
      expect(editor.getText()).toBe "\" something in here and in \"here\" \" and over here"
      expect(editor.getCursorScreenPosition()).toEqual [0, 39]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)

    it "expands an existing selection in visual mode", ->
      editor.setCursorScreenPosition([0, 25])
      keydown('v')
      keydown('l')
      keydown('l')
      keydown('l')
      keydown('l')
      keydown('i')
      keydown('"')

      expect(editor.getSelectedScreenRange()).toEqual [[0, 25], [0, 34]]

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
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "selects from the start of the current word to the start of the next word in visual mode", ->
      keydown('v')
      keydown('a')
      keydown('w')

      expect(editor.getSelectedScreenRange()).toEqual [[0, 6], [0, 12]]

    it "expands an existing selection in visual mode", ->
      editor.setCursorScreenPosition([0, 2])
      keydown('v')
      keydown('l')
      keydown('l')
      keydown('l')
      keydown('a')
      keydown('w')

      expect(editor.getSelectedScreenRange()).toEqual [[0, 2], [0, 12]]

    it "doesn't span newlines", ->
      editor.setText("12345\nabcde ABCDE")
      editor.setCursorBufferPosition([0, 3])

      keydown("v")
      keydown("a")
      keydown("w")

      expect(editor.getSelectedBufferRanges()).toEqual [[[0, 0], [0, 5]]]

    it "doesn't span special characters", ->
      editor.setText("1(345\nabcde ABCDE")
      editor.setCursorBufferPosition([0, 3])

      keydown("v")
      keydown("a")
      keydown("w")

      expect(editor.getSelectedBufferRanges()).toEqual [[[0, 2], [0, 5]]]

  describe "the 'aW' text object", ->
    beforeEach ->
      editor.setText("12(45 ab'de ABCDE")
      editor.setCursorScreenPosition([0, 9])

    it "applies operators from the start of the current whole word to the start of the next whole word in operator-pending mode", ->
      keydown('d')
      keydown('a')
      keydown('W', shift: true)

      expect(editor.getText()).toBe "12(45 ABCDE"
      expect(editor.getCursorScreenPosition()).toEqual [0, 6]
      expect(vimState.getRegister('"').text).toBe "ab'de "
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "selects from the start of the current whole word to the start of the next whole word in visual mode", ->
      keydown('v')
      keydown('a')
      keydown('W', shift: true)

      expect(editor.getSelectedScreenRange()).toEqual [[0, 6], [0, 12]]

    it "expands an existing selection in visual mode", ->
      editor.setCursorScreenPosition([0, 2])
      keydown('v')
      keydown('l')
      keydown('l')
      keydown('l')
      keydown('a')
      keydown('W', shift: true)

      expect(editor.getSelectedScreenRange()).toEqual [[0, 2], [0, 12]]

    it "doesn't span newlines", ->
      editor.setText("12(45\nab'de ABCDE")
      editor.setCursorBufferPosition([0, 4])

      keydown('v')
      keydown('a')
      keydown('W', shift: true)

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
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "applies operators around the current parentheses in operator-pending mode (second test)", ->
      editor.setCursorScreenPosition([0, 29])
      keydown('d')
      keydown('a')
      keydown('(')
      expect(editor.getText()).toBe "( something in here and in  )"
      expect(editor.getCursorScreenPosition()).toEqual [0, 27]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "expands an existing selection in visual mode", ->
      editor.setCursorScreenPosition([0, 25])
      keydown('v')
      keydown('l')
      keydown('l')
      keydown('l')
      keydown('l')
      keydown('a')
      keydown('(')

      expect(editor.getSelectedScreenRange()).toEqual [[0, 25], [0, 33]]

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
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "applies operators around the current curly brackets in operator-pending mode (second test)", ->
      editor.setCursorScreenPosition([0, 29])
      keydown('d')
      keydown('a')
      keydown('{')
      expect(editor.getText()).toBe "{ something in here and in  }"
      expect(editor.getCursorScreenPosition()).toEqual [0, 27]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "expands an existing selection in visual mode", ->
      editor.setCursorScreenPosition([0, 25])
      keydown('v')
      keydown('l')
      keydown('l')
      keydown('l')
      keydown('l')
      keydown('a')
      keydown('{')

      expect(editor.getSelectedScreenRange()).toEqual [[0, 25], [0, 33]]

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
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "applies operators around the current angle brackets in operator-pending mode (second test)", ->
      editor.setCursorScreenPosition([0, 29])
      keydown('d')
      keydown('a')
      keydown('<')
      expect(editor.getText()).toBe "< something in here and in  >"
      expect(editor.getCursorScreenPosition()).toEqual [0, 27]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "expands an existing selection in visual mode", ->
      editor.setCursorScreenPosition([0, 25])
      keydown('v')
      keydown('l')
      keydown('l')
      keydown('l')
      keydown('l')
      keydown('a')
      keydown('<')

      expect(editor.getSelectedScreenRange()).toEqual [[0, 25], [0, 33]]

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
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "applies operators around the current square brackets in operator-pending mode (second test)", ->
      editor.setCursorScreenPosition([0, 29])
      keydown('d')
      keydown('a')
      keydown('[')
      expect(editor.getText()).toBe "[ something in here and in  ]"
      expect(editor.getCursorScreenPosition()).toEqual [0, 27]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "expands an existing selection in visual mode", ->
      editor.setCursorScreenPosition([0, 25])
      keydown('v')
      keydown('l')
      keydown('l')
      keydown('l')
      keydown('l')
      keydown('a')
      keydown('[')

      expect(editor.getSelectedScreenRange()).toEqual [[0, 25], [0, 33]]

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
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "applies operators around the current single quotes in operator-pending mode (second test)", ->
      editor.setCursorScreenPosition([0, 29])
      keydown('d')
      keydown('a')
      keydown('\'')
      expect(editor.getText()).toBe "' something in here and in 'here"
      expect(editor.getCursorScreenPosition()).toEqual [0, 31]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "expands an existing selection in visual mode", ->
      editor.setCursorScreenPosition([0, 25])
      keydown('v')
      keydown('l')
      keydown('l')
      keydown('l')
      keydown('l')
      keydown('a')
      keydown('\'')

      expect(editor.getSelectedScreenRange()).toEqual [[0, 25], [0, 35]]

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
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "applies operators around the current double quotes in operator-pending mode (second test)", ->
      editor.setCursorScreenPosition([0, 29])
      keydown('d')
      keydown('a')
      keydown('"')
      expect(editor.getText()).toBe "\" something in here and in \"here"
      expect(editor.getCursorScreenPosition()).toEqual [0, 31]
      expect(editorElement.classList.contains('operator-pending-mode')).toBe(false)
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "expands an existing selection in visual mode", ->
      editor.setCursorScreenPosition([0, 25])
      keydown('v')
      keydown('l')
      keydown('l')
      keydown('l')
      keydown('l')
      keydown('a')
      keydown('"')

      expect(editor.getSelectedScreenRange()).toEqual [[0, 25], [0, 35]]
