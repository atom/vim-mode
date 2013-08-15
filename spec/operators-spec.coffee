$ = require 'jquery'

Keymap = require 'keymap'

helpers = require './spec-helper'

describe "Operators", ->
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

  describe "the x keybinding", ->
    it "deletes a character", ->
      editor.setText("012345")
      editor.setCursorScreenPosition([0, 4])

      keydown('x', element: editor[0])
      expect(editor.getText()).toBe '01235'
      expect(editor.getCursorScreenPosition()).toEqual([0, 4])
      expect(vimState.getRegister('"').text).toBe '4'

      keydown('x', element: editor[0])
      expect(editor.getText()).toBe '0123'
      expect(editor.getCursorScreenPosition()).toEqual([0, 3])
      expect(vimState.getRegister('"').text).toBe '5'

      keydown('x', element: editor[0])
      expect(editor.getText()).toBe '012'
      expect(editor.getCursorScreenPosition()).toEqual([0, 2])
      expect(vimState.getRegister('"').text).toBe '3'

    it "deletes nothing when cursor is on empty line", ->
      editor.getBuffer().setText "012345\n\nabcdef"
      editor.setCursorScreenPosition [1, 0]

      keydown('x', element: editor[0])
      expect(editor.getText()).toBe "012345\n\nabcdef"

  describe "the s keybinding", ->
    it "deletes the character to the right and enters insert mode", ->
      editor.setText("012345")
      editor.setCursorScreenPosition([0, 0])

      keydown('s', element: editor[0])
      expect(editor).toHaveClass 'insert-mode'
      expect(editor.getText()).toBe '12345'
      expect(editor.getCursorScreenPosition()).toEqual [0, 0]
      expect(vimState.getRegister('"').text).toBe '0'

    it "deletes count characters to the right and enters insert mode", ->
      editor.setText("012345")
      editor.setCursorScreenPosition([0, 1])

      keydown('3', element: editor[0])
      keydown('s', element: editor[0])
      expect(editor).toHaveClass 'insert-mode'
      expect(editor.getText()).toBe '045'
      expect(editor.getCursorScreenPosition()).toEqual [0, 1]
      expect(vimState.getRegister('"').text).toBe '123'

  describe "the S keybinding", ->
    it "deletes the entire line and enters insert mode", ->
      editor.setText("12345\nabcde\nABCDE")
      editor.setCursorScreenPosition([1,3])

      keydown('S', shift: true, element: editor[0])
      expect(editor).toHaveClass 'insert-mode'
      expect(editor.getText()).toBe "12345\n\nABCDE"
      expect(editor.getCursorScreenPosition()).toEqual [1, 0]
      expect(vimState.getRegister('"').text).toBe "abcde\n"
      expect(vimState.getRegister('"').type).toBe "linewise"

  describe "the d keybinding", ->
    describe "when followed by a d", ->
      it "deletes the current line", ->
        editor.setText("12345\nabcde\n\nABCDE")
        editor.setCursorScreenPosition([1,1])

        keydown('d', element: editor[0])
        keydown('d', element: editor[0])
        expect(editor.getText()).toBe "12345\n\nABCDE"
        expect(editor.getCursorScreenPosition()).toEqual([1,0])
        expect(vimState.getRegister('"').text).toBe "abcde\n"

      it "deletes the last line", ->
        editor.setText("12345\nabcde\nABCDE")
        editor.setCursorScreenPosition([2,1])
        keydown('d', element: editor[0])
        keydown('d', element: editor[0])
        expect(editor.getText()).toBe "12345\nabcde"
        expect(editor.getCursorScreenPosition()).toEqual([1,0])

      describe "when the second d is prefixed by a count", ->
        it "deletes n lines, starting from the current", ->
          editor.setText("12345\nabcde\nABCDE\nQWERT")
          editor.setCursorScreenPosition([1,1])

          keydown('d', element: editor[0])
          keydown('2', element: editor[0])
          keydown('d', element: editor[0])

          expect(editor.getText()).toBe "12345\nQWERT"
          expect(editor.getCursorScreenPosition()).toEqual([1,0])

    describe "when followed by an h", ->
      it "deletes the previous letter on the current line", ->
        editor.setText("abcd\n01234")
        editor.setCursorScreenPosition([1,1])

        keydown('d', element: editor[0])
        keydown('h', element: editor[0])

        expect(editor.getText()).toBe "abcd\n1234"
        expect(editor.getCursorScreenPosition()).toEqual([1,0])

        keydown('d', element: editor[0])
        keydown('h', element: editor[0])

        expect(editor.getText()).toBe "abcd\n1234"
        expect(editor.getCursorScreenPosition()).toEqual([1,0])

    describe "when followed by a w", ->
      it "deletes the next word until the end of the line", ->
        editor.setText("abcd efg\nabc")
        editor.setCursorScreenPosition([0,5])

        keydown('d', element: editor[0])
        keydown('w', element: editor[0])

        expect(editor.getText()).toBe "abcd \nabc"
        expect(editor.getCursorScreenPosition()).toEqual([0,4])

      it "deletes to the beginning of the next word", ->
        editor.setText("abcd efg")
        editor.setCursorScreenPosition([0,2])

        keydown('d', element: editor[0])
        keydown('w', element: editor[0])

        expect(editor.getText()).toBe "abefg"
        expect(editor.getCursorScreenPosition()).toEqual([0,2])

        editor.setText("one two three four")
        editor.setCursorScreenPosition([0,0])

        keydown('d', element: editor[0])
        keydown('3', element: editor[0])
        keydown('w', element: editor[0])

        expect(editor.getText()).toBe "four"
        expect(editor.getCursorScreenPosition()).toEqual([0,0])

    describe "when followed by a b", ->
      it "deletes to the beginning of the previous word", ->
        editor.setText("abcd efg")
        editor.setCursorScreenPosition([0,2])

        keydown('d', element: editor[0])
        keydown('b', element: editor[0])

        expect(editor.getText()).toBe "cd efg"
        expect(editor.getCursorScreenPosition()).toEqual([0,0])

        editor.setText("one two three four")
        editor.setCursorScreenPosition([0,11])

        keydown('d', element: editor[0])
        keydown('3', element: editor[0])
        keydown('b', element: editor[0])

        expect(editor.getText()).toBe "ee four"
        expect(editor.getCursorScreenPosition()).toEqual([0,0])

  describe "the D keybinding", ->
    beforeEach ->
      editor.getBuffer().setText "012\n"
      editor.setCursorScreenPosition [0, 1]

    it "deletes the contents until the end of the line", ->
      keydown('D', shift: true, element: editor[0])

      expect(editor.getText()).toBe "0\n"

  describe "the c keybinding", ->
    describe "when followed by a c", ->
      it "deletes the current line and enters insert mode", ->
        editor.setText("12345\nabcde\nABCDE")
        editor.setCursorScreenPosition([1,1])

        keydown('c', element: editor[0])
        keydown('c', element: editor[0])
        expect(editor.getText()).toBe "12345\nABCDE"
        expect(editor.getCursorScreenPosition()).toEqual([1,0])
        expect(editor).not.toHaveClass 'command-mode'
        expect(editor).toHaveClass 'insert-mode'

      it "deletes the last line and enters insert mode", ->
        editor.setText("12345\nabcde\nABCDE")
        editor.setCursorScreenPosition([2,1])
        keydown('c', element: editor[0])
        keydown('c', element: editor[0])
        expect(editor.getText()).toBe "12345\nabcde"
        expect(editor.getCursorScreenPosition()).toEqual([1,0])
        expect(editor).not.toHaveClass 'command-mode'
        expect(editor).toHaveClass 'insert-mode'

      describe "when the second c is prefixed by a count", ->
        it "deletes n lines, starting from the current, and enters insert mode", ->
          editor.setText("12345\nabcde\nABCDE\nQWERT")
          editor.setCursorScreenPosition([1,1])

          keydown('c', element: editor[0])
          keydown('2', element: editor[0])
          keydown('c', element: editor[0])

          expect(editor.getText()).toBe "12345\nQWERT"
          expect(editor.getCursorScreenPosition()).toEqual([1,0])
          expect(editor).not.toHaveClass 'command-mode'
          expect(editor).toHaveClass 'insert-mode'

    describe "when followed by an h", ->
      it "deletes the previous letter on the current line and enters insert mode", ->
        editor.setText("abcd\n01234")
        editor.setCursorScreenPosition([1,1])

        keydown('c', element: editor[0])
        keydown('h', element: editor[0])

        expect(editor.getText()).toBe "abcd\n1234"
        expect(editor.getCursorScreenPosition()).toEqual([1,0])
        expect(editor).not.toHaveClass 'command-mode'
        expect(editor).toHaveClass 'insert-mode'

    describe "when followed by a w", ->
      it "deletes to the beginning of the next word and enters insert mode", ->
        editor.setText("abcd efg")
        editor.setCursorScreenPosition([0,2])

        keydown('c', element: editor[0])
        keydown('w', element: editor[0])

        expect(editor.getText()).toBe "ab efg"
        expect(editor.getCursorScreenPosition()).toEqual([0,2])
        expect(editor).not.toHaveClass 'command-mode'
        expect(editor).toHaveClass 'insert-mode'

        keydown('escape', element: editor[0])

        editor.setText("one two three four")
        editor.setCursorScreenPosition([0,0])

        keydown('c', element: editor[0])
        keydown('3', element: editor[0])
        keydown('w', element: editor[0])

        expect(editor.getText()).toBe "four"
        expect(editor.getCursorScreenPosition()).toEqual([0,0])
        expect(editor).not.toHaveClass 'command-mode'
        expect(editor).toHaveClass 'insert-mode'

    describe "when followed by a b", ->
      it "deletes to the beginning of the previous word and enters insert mode", ->
        editor.setText("abcd efg")
        editor.setCursorScreenPosition([0,2])

        keydown('c', element: editor[0])
        keydown('b', element: editor[0])

        expect(editor.getText()).toBe "cd efg"
        expect(editor.getCursorScreenPosition()).toEqual([0,0])
        expect(editor).not.toHaveClass 'command-mode'
        expect(editor).toHaveClass 'insert-mode'

        keydown('escape', element: editor[0])

        editor.setText("one two three four")
        editor.setCursorScreenPosition([0,11])

        keydown('c', element: editor[0])
        keydown('3', element: editor[0])
        keydown('b', element: editor[0])

        expect(editor.getText()).toBe "ee four"
        expect(editor.getCursorScreenPosition()).toEqual([0,0])
        expect(editor).not.toHaveClass 'command-mode'
        expect(editor).toHaveClass 'insert-mode'

  describe "the C keybinding", ->
    beforeEach ->
      editor.getBuffer().setText "012\n"
      editor.setCursorScreenPosition [0, 1]

    it "deletes the contents until the end of the line and enters insert mode", ->
      keydown('C', shift: true, element: editor[0])

      expect(editor.getText()).toBe "0\n"
      expect(editor.getCursorScreenPosition()).toEqual([0,1])
      expect(editor).not.toHaveClass 'command-mode'
      expect(editor).toHaveClass 'insert-mode'

  describe "the y keybinding", ->
    beforeEach ->
      editor.getBuffer().setText "012 345\nabc\n"
      editor.setCursorScreenPosition [0, 4]

    it "saves the line to the default register", ->
      keydown('y', element: editor[0])
      keydown('y', element: editor[0])

      expect(vimState.getRegister('"').text).toBe "012 345\n"
      expect(editor.getCursorScreenPosition()).toEqual([0,4])

    describe "when the second y is prefixed by a count", ->
      it "copies n lines, starting from the current", ->
        keydown('y', element: editor[0])
        keydown('2', element: editor[0])
        keydown('y', element: editor[0])

        expect(vimState.getRegister('"').text).toBe "012 345\nabc\n"

    it "saves the line to the a register", ->
      keydown('"', element: editor[0])
      keydown('a', element: editor[0])
      keydown('y', element: editor[0])
      keydown('y', element: editor[0])

      expect(vimState.getRegister('a').text).toBe "012 345\n"

    it "saves the first word to the default register", ->
      keydown('y', element: editor[0])
      keydown('w', element: editor[0])

      expect(vimState.getRegister('"').text).toBe "345"

  describe "the Y keybinding", ->
    beforeEach ->
      editor.getBuffer().setText "012 345\nabc\n"
      editor.setCursorScreenPosition [0, 4]

    it "saves the line to the default register", ->
      keydown('Y', shift: true, element: editor[0])

      expect(vimState.getRegister('"').text).toBe "012 345\n"
      expect(editor.getCursorScreenPosition()).toEqual([0,4])

    describe "when prefixed by a count", ->
      it "copies n lines, starting from the current", ->
        keydown('2', element: editor[0])
        keydown('Y', shift: true, element: editor[0])

        expect(vimState.getRegister('"').text).toBe "012 345\nabc\n"

    it "saves the line to the a register", ->
      keydown('"', element: editor[0])
      keydown('a', element: editor[0])
      keydown('Y', shift: true, element: editor[0])

      expect(vimState.getRegister('a').text).toBe "012 345\n"

  describe "the p keybinding", ->
    describe 'character', ->
      beforeEach ->
        editor.getBuffer().setText "012\n"
        editor.setCursorScreenPosition [0, 0]
        vimState.setRegister('"', text: "345")
        vimState.setRegister('a', text: "a")

      it "inserts the contents of the default register", ->
        keydown('p', element: editor[0])

        expect(editor.getText()).toBe "034512\n"
        expect(editor.getCursorScreenPosition()).toEqual [0,4]

      it "inserts the contents of the 'a' register", ->
        keydown('"', element: editor[0])
        keydown('a', element: editor[0])
        keydown('p', element: editor[0])

        expect(editor.getText()).toBe "0a12\n"
        expect(editor.getCursorScreenPosition()).toEqual [0,2]

    describe 'linewise', ->
      beforeEach ->
        editor.getBuffer().setText "012\n"
        editor.setCursorScreenPosition [0, 1]
        vimState.setRegister('"', text: " 345\n", type: 'linewise')

      it "inserts the contents of the default register", ->
        keydown('p', element: editor[0])

        expect(editor.getText()).toBe "012\n 345\n"
        expect(editor.getCursorScreenPosition()).toEqual [1,1]

  describe "the P keybinding", ->
    describe 'character', ->
      beforeEach ->
        editor.getBuffer().setText "012\n"
        editor.setCursorScreenPosition [0, 0]
        vimState.setRegister('"', text: "345")
        vimState.setRegister('a', text: "a")

      it "inserts the contents of the default register", ->
        keydown('P', shift: true, element: editor[0])

        expect(editor.getText()).toBe "345012\n"
        expect(editor.getCursorScreenPosition()).toEqual [0,3]

      it "inserts the contents of the 'a' register", ->
        keydown('"', element: editor[0])
        keydown('a', element: editor[0])
        keydown('P', shift: true, element: editor[0])

        expect(editor.getText()).toBe "a012\n"
        expect(editor.getCursorScreenPosition()).toEqual [0,1]

    describe 'linewise', ->
      beforeEach ->
        editor.getBuffer().setText "012\n"
        editor.setCursorScreenPosition [0, 1]
        vimState.setRegister('"', text: " 345\n", type: 'linewise')

      it "inserts the contents of the default register", ->
        keydown('P', shift: true, element: editor[0])

        expect(editor.getText()).toBe " 345\n012\n"
        expect(editor.getCursorScreenPosition()).toEqual [0,1]

  describe "the O keybinding", ->
    beforeEach ->
      spyOn(editor.activeEditSession, 'shouldAutoIndent').andReturn(true)
      spyOn(editor.activeEditSession, 'autoIndentBufferRow').andCallFake (line) ->
        editor.indent()

      editor.getBuffer().setText "  abc\n  012\n"
      editor.setCursorScreenPosition [1, 1]

    it "switches to insert and adds a newline above the current one", ->
      keydown('O', shift: true, element: editor[0])

      expect(editor.getText()).toBe "  abc\n  \n  012\n"
      expect(editor.getCursorScreenPosition()).toEqual [1,2]
      expect(editor).toHaveClass 'insert-mode'

  describe "the o keybinding", ->
    beforeEach ->
      spyOn(editor.activeEditSession, 'shouldAutoIndent').andReturn(true)
      spyOn(editor.activeEditSession, 'autoIndentBufferRow').andCallFake (line) ->
        editor.indent()

      editor.getBuffer().setText "abc\n  012\n"
      editor.setCursorScreenPosition [1, 2]

    it "switches to insert and adds a newline above the current one", ->
      keydown('o', element: editor[0])

      expect(editor.getText()).toBe "abc\n  012\n  \n"
      expect(editor).toHaveClass 'insert-mode'
      expect(editor.getCursorScreenPosition()).toEqual [2,2]

  describe "the a keybinding", ->
    beforeEach ->
      editor.getBuffer().setText "012\n"

    it "switches to insert mode and shifts to the right", ->
      editor.setCursorScreenPosition [0, 0]
      keydown('a', element: editor[0])

      expect(editor.getCursorScreenPosition()).toEqual [0,1]
      expect(editor).toHaveClass 'insert-mode'

    it "doesn't linewrap", ->
      editor.setCursorScreenPosition [0, 3]
      keydown('a', element: editor[0])

      expect(editor.getCursorScreenPosition()).toEqual [0,3]

  describe "the J keybinding", ->
    beforeEach ->
      editor.getBuffer().setText "012\n    456\n"
      editor.setCursorScreenPosition [0, 1]

    it "deletes the contents until the end of the line", ->
      keydown('J', shift: true, element: editor[0])

      expect(editor.getText()).toBe "012 456\n"

  describe "the > keybinding", ->
    describe "when followed by a >", ->
      it "indents the current line", ->
        editor.setText("12345\nabcde\nABCDE")
        editor.setCursorScreenPosition([1,1])

        keydown('>', element: editor[0])
        keydown('>', element: editor[0])
        expect(editor.getText()).toBe "12345\n  abcde\nABCDE"
        expect(editor.getCursorScreenPosition()).toEqual([1,2])

      it "indents multiple lines at once", ->
        editor.setText("12345\nabcde\nABCDE")
        editor.setCursorScreenPosition([0,0])

        keydown('3', element: editor[0])
        keydown('>', element: editor[0])
        keydown('>', element: editor[0])
        expect(editor.getText()).toBe "  12345\n  abcde\n  ABCDE"
        expect(editor.getCursorScreenPosition()).toEqual([0,2])

        keydown('u', element: editor[0])
        expect(editor.getText()).toBe "12345\nabcde\nABCDE"


  describe "the < keybinding", ->
    describe "when followed by a <", ->
      it "indents the current line", ->
        expect(editor.setText("12345\n  abcde\nABCDE"))
        editor.setCursorScreenPosition([1,2])

        keydown('<', element: editor[0])
        keydown('<', element: editor[0])
        expect(editor.getText()).toBe "12345\nabcde\nABCDE"
        expect(editor.getCursorScreenPosition()).toEqual([1,0])

      it "indents multiple lines at once", ->
        editor.setText("  12345\n  abcde\n  ABCDE")
        editor.setCursorScreenPosition([0,0])

        keydown('3', element: editor[0])
        keydown('<', element: editor[0])
        keydown('<', element: editor[0])
        expect(editor.getText()).toBe "12345\nabcde\nABCDE"
        expect(editor.getCursorScreenPosition()).toEqual([0,0])

        keydown('u', element: editor[0])
        expect(editor.getText()).toBe "  12345\n  abcde\n  ABCDE"
