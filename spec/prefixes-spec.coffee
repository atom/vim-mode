helpers = require './spec-helper'

describe "Prefixes", ->
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

  describe "Repeat", ->
    describe "with operations", ->
      beforeEach ->
        editor.setText("123456789abc")
        editor.setCursorScreenPosition([0, 0])

      it "repeats N times", ->
        keydown('3')
        keydown('x')

        expect(editor.getText()).toBe '456789abc'

      it "repeats NN times", ->
        keydown('1')
        keydown('0')
        keydown('x')

        expect(editor.getText()).toBe 'bc'

    describe "with motions", ->
      beforeEach ->
        editor.setText('one two three')
        editor.setCursorScreenPosition([0, 0])

      it "repeats N times", ->
        keydown('d')
        keydown('2')
        keydown('w')

        expect(editor.getText()).toBe 'three'

    describe "in visual mode", ->
      beforeEach ->
        editor.setText('one two three')
        editor.setCursorScreenPosition([0, 0])

      it "repeats movements in visual mode", ->
        keydown("v")
        keydown("2")
        keydown("w")

        expect(editor.getCursorScreenPosition()).toEqual [0, 9]

  describe "Register", ->
    describe "the a register", ->
      it "saves a value for future reading", ->
        vimState.setRegister('a', text: 'new content')
        expect(vimState.getRegister("a").text).toEqual 'new content'

      it "overwrites a value previously in the register", ->
        vimState.setRegister('a', text: 'content')
        vimState.setRegister('a', text: 'new content')
        expect(vimState.getRegister("a").text).toEqual 'new content'

    describe "the B register", ->
      it "saves a value for future reading", ->
        vimState.setRegister('B', text: 'new content')
        expect(vimState.getRegister("b").text).toEqual 'new content'
        expect(vimState.getRegister("B").text).toEqual 'new content'

      it "appends to a value previously in the register", ->
        vimState.setRegister('b', text: 'content')
        vimState.setRegister('B', text: 'new content')
        expect(vimState.getRegister("b").text).toEqual 'contentnew content'

      it "appends linewise to a linewise value previously in the register", ->
        vimState.setRegister('b', {type: 'linewise', text: 'content\n'})
        vimState.setRegister('B', text: 'new content')
        expect(vimState.getRegister("b").text).toEqual 'content\nnew content\n'

      it "appends linewise to a character value previously in the register", ->
        vimState.setRegister('b', text: 'content')
        vimState.setRegister('B', {type: 'linewise', text: 'new content\n'})
        expect(vimState.getRegister("b").text).toEqual 'content\nnew content\n'


    describe "the * register", ->
      describe "reading", ->
        it "is the same the system clipboard", ->
          expect(vimState.getRegister('*').text).toEqual 'initial clipboard content'
          expect(vimState.getRegister('*').type).toEqual 'character'

      describe "writing", ->
        beforeEach ->
          vimState.setRegister('*', text: 'new content')

        it "overwrites the contents of the system clipboard", ->
          expect(atom.clipboard.read()).toEqual 'new content'

    # FIXME: once linux support comes out, this needs to read from
    # the correct clipboard. For now it behaves just like the * register
    # See :help x11-cut-buffer and :help registers for more details on how these
    # registers work on an X11 based system.
    describe "the + register", ->
      describe "reading", ->
        it "is the same the system clipboard", ->
          expect(vimState.getRegister('*').text).toEqual 'initial clipboard content'
          expect(vimState.getRegister('*').type).toEqual 'character'

      describe "writing", ->
        beforeEach ->
          vimState.setRegister('*', text: 'new content')

        it "overwrites the contents of the system clipboard", ->
          expect(atom.clipboard.read()).toEqual 'new content'

    describe "the _ register", ->
      describe "reading", ->
        it "is always the empty string", ->
          expect(vimState.getRegister("_").text).toEqual ''

      describe "writing", ->
        it "throws away anything written to it", ->
          vimState.setRegister('_', text: 'new content')
          expect(vimState.getRegister("_").text).toEqual ''

    describe "the % register", ->
      beforeEach ->
        spyOn(editor, 'getURI').andReturn('/Users/atom/known_value.txt')

      describe "reading", ->
        it "returns the filename of the current editor", ->
          expect(vimState.getRegister('%').text).toEqual '/Users/atom/known_value.txt'

      describe "writing", ->
        it "throws away anything written to it", ->
          vimState.setRegister('%', "new content")
          expect(vimState.getRegister('%').text).toEqual '/Users/atom/known_value.txt'

    describe "the 0 register", ->
      beforeEach ->
        editor.setText("1111\n2222\n3333\n4444")
        editor.setCursorScreenPosition([1, 0])
      describe "reading", ->
        it "returns the last text yanked without specifying a register"
          keydown('y')
          keydown('y')
          expect(vimState.getRegister("0").text).toEqual '2222'
          keydown('d')
          keydown('d')
          expect(vimState.getRegister("0").text).toEqual '2222'

      describe "writing", ->
        it "overwrites the last value that was yanked", ->
          keydown('y')
          keydown('y')
          expect(vimState.getRegister("0").text).toEqual '2222'
          keydown('j')
          keydown('y')
          keydown('y')
          expect(vimState.getRegister("0").text).toEqual '3333'

    describe "the 1..9 registers", ->
      beforeEach ->
        editor.setText("1111\n2222\n3333\n4444\n5555\n6666\n7777")
        editor.setCursorScreenPosition([1, 0])
      describe "reading", ->
        it "returns the text that was deleted n deletes ago (n=1 for the most recent delete)"
          keydown('d')
          keydown('d')
          expect(vimState.getRegister("1").text).toEqual '2222'

      describe "writing", ->
        it "saves the last line-oriented delete in 1 and moves all previous numbered registers to n+1", ->
          keydown('d')
          keydown('d')
          keydown('2')
          keydown('d')
          keydown('d')
          keydown('d')
          keydown('d')
          expect(vimState.getRegister("1").text).toEqual '5555'
          expect(vimState.getRegister("2").text).toEqual '3333\n4444'
          expect(vimState.getRegister("3").text).toEqual '2222'

    describe "the - register ('small' register)", ->
      beforeEach ->
        editor.setText("line 1\nword1 word2 word3\nabcdefghijklmno")
        editor.setCursorScreenPosition([1, 7])
      describe "reading", ->
        it "returns the last non-linewise text deleted/changed without specifying a register"
          keydown('d')
          keydown('w')
          expect(vimState.getRegister("-").text).toEqual 'word2'

      describe "writing", ->
        it "is written by deleting or changing text within a line", ->
          keydown('d')
          keydown('w')
          expect(vimState.getRegister("-").text).toEqual 'word2'
          keydown('j')
          keydown('d')
          keydown('$')
          expect(vimState.getRegister("-").text).toEqual 'ghijklmno'

    describe "the ctrl-r command in insert mode", ->
      beforeEach ->
        editor.setText "02\n"
        editor.setCursorScreenPosition [0, 0]
        vimState.setRegister('"', text: '345')
        vimState.setRegister('a', text: 'abc')
        atom.clipboard.write "clip"
        keydown 'a'
        editor.insertText '1'

      it "inserts contents of the unnamed register with \"", ->
        keydown 'r', ctrl: true
        keydown '"'
        expect(editor.getText()).toBe '013452\n'

      describe "when useClipboardAsDefaultRegister enabled", ->
        it "inserts contents from clipboard with \"", ->
          atom.config.set 'vim-mode.useClipboardAsDefaultRegister', true
          keydown 'r', ctrl: true
          keydown '"'
          expect(editor.getText()).toBe '01clip2\n'

      it "inserts contents of the 'a' register", ->
        keydown 'r', ctrl: true
        keydown 'a'
        expect(editor.getText()).toBe '01abc2\n'

      it "is cancelled with the escape key", ->
        keydown 'r', ctrl: true
        keydown 'escape'
        expect(editor.getText()).toBe '012\n'
        expect(vimState.mode).toBe "insert"
        expect(editor.getCursorScreenPosition()).toEqual [0, 2]
