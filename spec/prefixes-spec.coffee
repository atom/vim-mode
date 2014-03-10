helpers = require './spec-helper'

describe "Prefixes", ->
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

  describe "Register", ->
    describe "the a register", ->
      it "saves a value for future reading", ->
        vimState.setRegister('a', text: 'new content')
        expect(vimState.getRegister("a").text).toEqual 'new content'

      it "overwrites a value previously in the register", ->
        vimState.setRegister('a', text: 'content')
        vimState.setRegister('a', text: 'new content')
        expect(vimState.getRegister("a").text).toEqual 'new content'


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
    # the correct system clipboard. For now it behaves just like the * register
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

    # FIXME: @editor.getUri() is returning undefined. Not sure how to setup
    # the @editor instance in test most.
    xdescribe "the % register", ->
      describe "reading", ->
        it "returns the filename of the current editor", ->
          expect(vimState.getRegister('%').text).toEqual 'fjdka'

      describe "writing", ->
        it "throws away anything written to it", ->
          vimState.setRegister('%', "new content")
          expect(vimState.getRegister('%').text).toEqual 'fjdka'
