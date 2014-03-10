helpers = require './spec-helper'

describe "Operators", ->
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

  describe "the x keybinding", ->
    describe "on a line with content", ->
      beforeEach ->
        editor.setText("012345")
        editor.setCursorScreenPosition([0, 4])

      it "deletes a character", ->
        keydown('x')
        expect(editor.getText()).toBe '01235'
        expect(editor.getCursorScreenPosition()).toEqual [0, 4]
        expect(vimState.getRegister('"').text).toBe '4'

        keydown('x')
        expect(editor.getText()).toBe '0123'
        expect(editor.getCursorScreenPosition()).toEqual [0, 3]
        expect(vimState.getRegister('"').text).toBe '5'

        keydown('x')
        expect(editor.getText()).toBe '012'
        expect(editor.getCursorScreenPosition()).toEqual [0, 2]
        expect(vimState.getRegister('"').text).toBe '3'

    describe "on an empty line", ->
      beforeEach ->
        editor.setText("012345\n\nabcdef")
        editor.setCursorScreenPosition([1, 0])
        keydown('x')

      it "deletes nothing when cursor is on empty line", ->
        expect(editor.getText()).toBe "012345\n\nabcdef"

  describe "the X keybinding", ->
    describe "on a line with content", ->
      beforeEach ->
        editor.setText("012345")
        editor.setCursorScreenPosition([0, 2])

      it "deletes a character", ->
        keydown('X', shift: true)
        expect(editor.getText()).toBe '02345'
        expect(editor.getCursorScreenPosition()).toEqual [0, 1]
        expect(vimState.getRegister('"').text).toBe '1'

        keydown('X', shift: true)
        expect(editor.getText()).toBe '2345'
        expect(editor.getCursorScreenPosition()).toEqual [0, 0]
        expect(vimState.getRegister('"').text).toBe '0'

        keydown('X', shift: true)
        expect(editor.getText()).toBe '2345'
        expect(editor.getCursorScreenPosition()).toEqual [0, 0]
        expect(vimState.getRegister('"').text).toBe '0'

    describe "on an empty line", ->
      beforeEach ->
        editor.setText("012345\n\nabcdef")
        editor.setCursorScreenPosition([1, 0])
        keydown('X', shift: true)

      it "deletes nothing when cursor is on empty line", ->
        expect(editor.getText()).toBe "012345\n\nabcdef"

  describe "the s keybinding", ->
    beforeEach ->
      editor.setText('012345')
      editor.setCursorScreenPosition([0, 1])
      keydown('s')

    it "deletes the character to the right and enters insert mode", ->
      expect(editorView).toHaveClass 'insert-mode'
      expect(editor.getText()).toBe '02345'
      expect(editor.getCursorScreenPosition()).toEqual [0, 1]
      expect(vimState.getRegister('"').text).toBe '1'

  describe "the S keybinding", ->
    beforeEach ->
      editor.setText("12345\nabcde\nABCDE")
      editor.setCursorScreenPosition([1, 3])
      keydown('S', shift: true)

    it "deletes the entire line and enters insert mode", ->
      expect(editorView).toHaveClass 'insert-mode'
      expect(editor.getText()).toBe "12345\n\nABCDE"
      expect(editor.getCursorScreenPosition()).toEqual [1, 0]
      expect(vimState.getRegister('"').text).toBe "abcde\n"
      expect(vimState.getRegister('"').type).toBe 'linewise'

  describe "the d keybinding", ->
    describe "when followed by a d", ->
      it "deletes the current line", ->
        editor.setText("12345\nabcde\n\nABCDE")
        editor.setCursorScreenPosition([1, 1])

        keydown('d')
        keydown('d')

        expect(editor.getText()).toBe "12345\n\nABCDE"
        expect(editor.getCursorScreenPosition()).toEqual [1, 0]
        expect(vimState.getRegister('"').text).toBe "abcde\n"

      it "deletes the last line", ->
        editor.setText("12345\nabcde\nABCDE")
        editor.setCursorScreenPosition([2, 1])

        keydown('d')
        keydown('d')

        expect(editor.getText()).toBe "12345\nabcde"
        expect(editor.getCursorScreenPosition()).toEqual [1, 0]

    describe "undo behavior", ->
      beforeEach ->
        editor.setText("12345\nabcde\nABCDE\nQWERT")
        editor.setCursorScreenPosition([1,1])

        keydown('d')
        keydown('2')
        keydown('d')

        keydown('u')

      it "undoes both lines", ->
        expect(editor.getText()).toBe "12345\nabcde\nABCDE\nQWERT"

    describe "when followed by a w", ->
      it "deletes the next word until the end of the line", ->
        editor.setText("abcd efg\nabc")
        editor.setCursorScreenPosition([0, 5])

        keydown('d')
        keydown('w')

        expect(editor.getText()).toBe "abcd \nabc"
        expect(editor.getCursorScreenPosition()).toEqual [0, 4]

      it "deletes to the beginning of the next word", ->
        editor.setText('abcd efg')
        editor.setCursorScreenPosition([0, 2])

        keydown('d')
        keydown('w')

        expect(editor.getText()).toBe 'abefg'
        expect(editor.getCursorScreenPosition()).toEqual [0, 2]

        editor.setText('one two three four')
        editor.setCursorScreenPosition([0, 0])

        keydown('d')
        keydown('3')
        keydown('w')

        expect(editor.getText()).toBe 'four'
        expect(editor.getCursorScreenPosition()).toEqual [0, 0]

  describe "the D keybinding", ->
    beforeEach ->
      editor.getBuffer().setText("012\n")
      editor.setCursorScreenPosition([0, 1])
      keydown('D', shift: true)

    it "deletes the contents until the end of the line", ->
      expect(editor.getText()).toBe "0\n"

  describe "the c keybinding", ->
    describe "when followed by a c", ->
      beforeEach ->
        editor.setText("12345\nabcde\nABCDE")

      it "deletes the current line and enters insert mode", ->
        editor.setCursorScreenPosition([1, 1])

        keydown('c')
        keydown('c')

        expect(editor.getText()).toBe "12345\nABCDE"
        expect(editor.getCursorScreenPosition()).toEqual [1, 0]
        expect(editorView).not.toHaveClass 'command-mode'
        expect(editorView).toHaveClass 'insert-mode'

      it "deletes the last line and enters insert mode", ->
        editor.setCursorScreenPosition([2, 1])

        keydown('c')
        keydown('c')

        expect(editor.getText()).toBe "12345\nabcde"
        expect(editor.getCursorScreenPosition()).toEqual [1, 0]
        expect(editorView).not.toHaveClass 'command-mode'
        expect(editorView).toHaveClass 'insert-mode'

  describe "the C keybinding", ->
    beforeEach ->
      editor.getBuffer().setText("012\n")
      editor.setCursorScreenPosition([0, 1])
      keydown('C', shift: true)

    it "deletes the contents until the end of the line and enters insert mode", ->
      expect(editor.getText()).toBe "0\n"
      expect(editor.getCursorScreenPosition()).toEqual [0, 1]
      expect(editorView).not.toHaveClass 'command-mode'
      expect(editorView).toHaveClass 'insert-mode'

  describe "the y keybinding", ->
    beforeEach ->
      editor.getBuffer().setText("012 345\nabc\n")
      editor.setCursorScreenPosition([0, 4])

    describe "when selected lines in visual linewise mode", ->
      beforeEach ->
        keydown('V', shift: true)
        keydown('j')
        keydown('y')

      it "is in linewise motion", ->
        expect(vimState.getRegister('"').type).toEqual "linewise"

      it "saves the lines to the default register", ->
        expect(vimState.getRegister('"').text).toBe "012 345\nabc\n"

    describe "when followed by a second y ", ->
      beforeEach ->
        keydown('y')
        keydown('y')

      it "saves the line to the default register", ->
        expect(vimState.getRegister('"').text).toBe "012 345\n"
        expect(editor.getCursorScreenPosition()).toEqual [0, 4]

    describe "when followed with a repeated y", ->
      beforeEach ->
        keydown('y')
        keydown('2')
        keydown('y')

      it "copies n lines, starting from the current", ->
        expect(vimState.getRegister('"').text).toBe "012 345\nabc\n"

    describe "with a register", ->
      beforeEach ->
        keydown('"')
        keydown('a')
        keydown('y')
        keydown('y')

      it "saves the line to the a register", ->
        expect(vimState.getRegister('a').text).toBe "012 345\n"

    describe "with a motion", ->
      beforeEach ->
        keydown('y')
        keydown('w')

      it "saves the first word to the default register", ->
        expect(vimState.getRegister('"').text).toBe '345'

  describe "the Y keybinding", ->
    beforeEach ->
      editor.getBuffer().setText "012 345\nabc\n"
      editor.setCursorScreenPosition [0, 4]

    it "saves the line to the default register", ->
      keydown('Y', shift: true)

      expect(vimState.getRegister('"').text).toBe "012 345\n"
      expect(editor.getCursorScreenPosition()).toEqual [0, 4]

  describe "the p keybinding", ->
    describe "with character contents", ->
      beforeEach ->
        editor.getBuffer().setText "012\n"
        editor.setCursorScreenPosition [0, 0]
        vimState.setRegister('"', text: '345')
        vimState.setRegister('a', text: 'a')

      describe "from the default register", ->
        beforeEach -> keydown('p')

        it "inserts the contents", ->
          expect(editor.getText()).toBe "034512\n"
          expect(editor.getCursorScreenPosition()).toEqual [0, 4]

      describe "from a specified register", ->
        beforeEach ->
          keydown('"')
          keydown('a')
          keydown('p')

        it "inserts the contents of the 'a' register", ->
          expect(editor.getText()).toBe "0a12\n"
          expect(editor.getCursorScreenPosition()).toEqual [0, 2]

      describe "at the end of a line", ->
        it "inserts before the current line's newline", ->
          editor.setText("abcde\none two three")
          editor.setCursorScreenPosition([1, 4])

          keydown 'd'
          keydown '$'
          keydown 'k'
          keydown '$'
          keydown 'p'

          expect(editor.getText()).toBe "abcdetwo three\none "


    describe "with linewise contents", ->
      beforeEach ->
        editor.getBuffer().setText("012")
        editor.setCursorScreenPosition([0, 1])
        vimState.setRegister('"', text: " 345\n", type: 'linewise')
        keydown('p')

      it "inserts the contents of the default register", ->
        expect(editor.getText()).toBe "012\n 345"
        expect(editor.getCursorScreenPosition()).toEqual [1, 1]

    describe "with multiple linewise contents", ->
      beforeEach ->
        editor.getBuffer().setText("012\nabc")
        editor.setCursorScreenPosition([1, 0])
        vimState.setRegister('"', text: " 345\n 678\n", type: 'linewise')
        keydown('p')

      it "inserts the contents of the default register", ->
        expect(editor.getText()).toBe "012\nabc\n 345\n 678"
        expect(editor.getCursorScreenPosition()).toEqual [2, 1]

    describe "pasting twice", ->
      beforeEach ->
        editor.setText("12345\nabcde\nABCDE\nQWERT")
        editor.setCursorScreenPosition([1, 1])
        vimState.setRegister('"', text: '123')
        keydown('2')
        keydown('p')

      it "inserts the same line twice", ->
        expect(editor.getText()).toBe "12345\nab123123cde\nABCDE\nQWERT"

      describe "when undone", ->
        beforeEach ->
          keydown('u')

        it "removes both lines", ->
          expect(editor.getText()).toBe "12345\nabcde\nABCDE\nQWERT"

  describe "the P keybinding", ->
    describe "with character contents", ->
      beforeEach ->
        editor.getBuffer().setText("012\n")
        editor.setCursorScreenPosition([0, 0])
        vimState.setRegister('"', text: '345')
        vimState.setRegister('a', text: 'a')
        keydown('P', shift: true)

      it "inserts the contents of the default register above", ->
        expect(editor.getText()).toBe "345012\n"
        expect(editor.getCursorScreenPosition()).toEqual [0, 3]

  describe "the O keybinding", ->
    beforeEach ->
      spyOn(editor, 'shouldAutoIndent').andReturn(true)
      spyOn(editor, 'autoIndentBufferRow').andCallFake (line) ->
        editor.indent()

      editor.getBuffer().setText("  abc\n  012\n")
      editor.setCursorScreenPosition([1, 1])
      keydown('O', shift: true)

    it "switches to insert and adds a newline above the current one", ->
      expect(editor.getText()).toBe "  abc\n  \n  012\n"
      expect(editor.getCursorScreenPosition()).toEqual [1, 2]
      expect(editorView).toHaveClass 'insert-mode'

  describe "the o keybinding", ->
    beforeEach ->
      spyOn(editor, 'shouldAutoIndent').andReturn(true)
      spyOn(editor, 'autoIndentBufferRow').andCallFake (line) ->
        editor.indent()

      editor.getBuffer().setText("abc\n  012\n")
      editor.setCursorScreenPosition([1, 2])
      keydown('o')

    it "switches to insert and adds a newline above the current one", ->
      expect(editor.getText()).toBe "abc\n  012\n  \n"
      expect(editorView).toHaveClass 'insert-mode'
      expect(editor.getCursorScreenPosition()).toEqual [2, 2]

  describe "the a keybinding", ->
    beforeEach ->
      editor.getBuffer().setText("012\n")

    describe "at the beginning of the line", ->
      beforeEach ->
        editor.setCursorScreenPosition([0, 0])
        keydown('a')

      it "switches to insert mode and shifts to the right", ->
        expect(editor.getCursorScreenPosition()).toEqual [0, 1]
        expect(editorView).toHaveClass 'insert-mode'

    describe "at the end of the line", ->
      beforeEach ->
        editor.setCursorScreenPosition([0, 3])
        keydown('a')

      it "doesn't linewrap", ->
        expect(editor.getCursorScreenPosition()).toEqual [0, 3]

  describe "the A keybinding", ->
    beforeEach ->
      editor.getBuffer().setText("11\n22\n")

    describe "at the beginning of a line", ->
      it "switches to insert mode at the end of the line", ->
        editor.setCursorScreenPosition([0,0])
        keydown('A', shift: true)

        expect(editorView).toHaveClass 'insert-mode'
        expect(editor.getCursorScreenPosition()).toEqual [0, 2]

  describe "the I keybinding", ->
    beforeEach ->
      editor.getBuffer().setText("11\n  22\n")

    describe "at the end of a line", ->
      it "switches to insert mode at the beginning of the line", ->
        editor.setCursorScreenPosition([0,2])
        keydown('I', shift: true)

        expect(editorView).toHaveClass 'insert-mode'
        expect(editor.getCursorScreenPosition()).toEqual [0, 0]

      it "switches to insert mode after leading whitespace", ->
        editor.setCursorScreenPosition([1,4])
        keydown('I', shift: true)

        expect(editorView).toHaveClass 'insert-mode'
        expect(editor.getCursorScreenPosition()).toEqual [1, 2]

  describe "the J keybinding", ->
    beforeEach ->
      editor.getBuffer().setText("012\n    456\n")
      editor.setCursorScreenPosition([0, 1])

    describe "without repeating", ->
      beforeEach -> keydown('J', shift: true)

      it "joins the contents of the current line with the one below it", ->
        expect(editor.getText()).toBe "012 456\n"

    describe "with repeating", ->
      beforeEach ->
        editor.setText("12345\nabcde\nABCDE\nQWERT")
        editor.setCursorScreenPosition([1, 1])
        keydown('2')
        keydown('J', shift: true)

      describe "undo behavior", ->
        beforeEach -> keydown('u')

        it "handles repeats", ->
          expect(editor.getText()).toBe "12345\nabcde\nABCDE\nQWERT"

  describe "the > keybinding", ->
    beforeEach ->
      editor.setText("12345\nabcde\nABCDE")

    describe "on the last line", ->
      beforeEach ->
        editor.setCursorScreenPosition([2, 0])

      describe "when followed by a >", ->
        beforeEach ->
          keydown('>')
          keydown('>')

        it "indents the current line", ->
          expect(editor.getText()).toBe "12345\nabcde\n  ABCDE"
          expect(editor.getCursorScreenPosition()).toEqual [2, 2]

    describe "on the first line", ->
      beforeEach ->
        editor.setCursorScreenPosition([0, 0])

      describe "when followed by a >", ->
        beforeEach ->
          keydown('>')
          keydown('>')

        it "indents the current line", ->
          expect(editor.getText()).toBe "  12345\nabcde\nABCDE"
          expect(editor.getCursorScreenPosition()).toEqual [0, 2]

      describe "when followed by a repeating >", ->
        beforeEach ->
          keydown('3')
          keydown('>')
          keydown('>')

        it "indents multiple lines at once", ->
          expect(editor.getText()).toBe "  12345\n  abcde\n  ABCDE"
          expect(editor.getCursorScreenPosition()).toEqual [0, 2]

        describe "undo behavior", ->
          beforeEach -> keydown('u')

          it "outdents all three lines", ->
            expect(editor.getText()).toBe "12345\nabcde\nABCDE"

  describe "the < keybinding", ->
    beforeEach ->
      editor.setText("  12345\n  abcde\nABCDE")
      editor.setCursorScreenPosition([0, 0])

    describe "when followed by a <", ->
      beforeEach ->
        keydown('<')
        keydown('<')

      it "indents the current line", ->
        expect(editor.getText()).toBe "12345\n  abcde\nABCDE"
        expect(editor.getCursorScreenPosition()).toEqual [0, 0]

    describe "when followed by a repeating <", ->
      beforeEach ->
        keydown('2')
        keydown('<')
        keydown('<')

      it "indents multiple lines at once", ->
        expect(editor.getText()).toBe "12345\nabcde\nABCDE"
        expect(editor.getCursorScreenPosition()).toEqual [0, 0]

      describe "undo behavior", ->
        beforeEach -> keydown('u')

        it "indents both lines", ->
          expect(editor.getText()).toBe "  12345\n  abcde\nABCDE"

  describe "the = keybinding", ->
    oldGrammar = []

    beforeEach ->
      waitsForPromise ->
        atom.packages.activatePackage('language-javascript')

      oldGrammar = editor.getGrammar()
      editor.setText("foo\n  bar\n  baz")
      editor.setCursorScreenPosition([1, 0])

    describe "when used in a scope that supports auto-indent", ->
      beforeEach ->
        jsGrammar = atom.syntax.grammarForScopeName('source.js')
        editor.setGrammar(jsGrammar)

      afterEach ->
        editor.setGrammar(oldGrammar)

      describe "when followed by a =", ->
        beforeEach ->
          keydown('=')
          keydown('=')

        it "indents the current line", ->
          expect(editor.indentationForBufferRow(1)).toBe 0

      describe "when followed by a repeating =", ->
        beforeEach ->
          keydown('2')
          keydown('=')
          keydown('=')

        it "autoindents multiple lines at once", ->
          expect(editor.getText()).toBe "foo\nbar\nbaz"
          expect(editor.getCursorScreenPosition()).toEqual [1, 0]

        describe "undo behavior", ->
          beforeEach -> keydown('u')

          it "indents both lines", ->
            expect(editor.getText()).toBe "foo\n  bar\n  baz"

  describe "the . keybinding", ->
    beforeEach ->
      editor.setText("12\n34\n56\n78")
      editor.setCursorScreenPosition([0,0])

    it "repeats the last operation", ->
      keydown '2'
      keydown 'd'
      keydown 'd'
      keydown '.'

      expect(editor.getText()).toBe ""

    it "composes with motions", ->
      keydown 'd'
      keydown 'd'
      keydown '2'
      keydown '.'

      expect(editor.getText()).toBe "78"

  describe "the r keybinding", ->
    beforeEach ->
      editor.setText("12\n34\n\n")
      editor.setCursorBufferPosition([0,0])

    it "replaces a single character", ->
      keydown('r')
      commandModeInputKeydown('x')
      expect(editor.getText()).toBe 'x2\n34\n\n'

    it "composes properly with motions", ->
      keydown('2')
      keydown('r')
      commandModeInputKeydown('x')
      expect(editor.getText()).toBe 'xx\n34\n\n'

    it "does nothing on an empty line", ->
      editor.setCursorBufferPosition([2, 0])
      keydown('r')
      commandModeInputKeydown('x')
      expect(editor.getText()).toBe '12\n34\n\n'

    it "does nothing if asked to replace more characters than there are on a line", ->
      keydown('3')
      keydown('r')
      commandModeInputKeydown('x')
      expect(editor.getText()).toBe '12\n34\n\n'
