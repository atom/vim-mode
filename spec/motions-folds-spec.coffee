_ = require 'underscore-plus'
helpers = require './spec-helper'
path = require 'path'
{WorkspaceView} = require 'atom'

describe "Motions", ->
  [editor, editorView, vimModePromise] = []

  afterEach ->
    waitsFor ->
      atom.packages.deactivatePackage 'vim-mode'

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    atom.project.setPath(path.join(__dirname, 'fixtures'))

    waitsForPromise ->
      atom.workspace.open 'fold-text.md'

    runs ->
      atom.workspaceView.attachToDom()
      editorView = atom.workspaceView.getActiveView()
      editor = editorView.getEditor()
      vimModePromise = atom.packages.activatePackage 'vim-mode'

    waitsForPromise ->
      vimModePromise

  keydown = (key, options={}) ->
    options.element ?= editorView[0]
    helpers.keydown(key, options)

  describe "motions under folded code", ->
    initFold = ->
      keydown 'j'
      _.times 4, -> keydown 'l'
      expect(editor.getCursorScreenPosition()).toEqual [1, 6]
      editor.foldCurrentRow()
      expect(editor.getCursorScreenPosition()).toEqual [1, 0]

    beforeEach ->
      initFold()

    describe "the l keybinding", ->
      describe "as a motion", ->
        it "moves the cursor to next non folded line,
          but stops at end of normal line", ->
          _.times 50, -> keydown 'l'
          # scrolls to next line and end of next line
          expect(editor.getCursorScreenPosition()).toEqual [2, 12]

        it "moves the cursor right, but not beyond end of line", ->
          _.times 2, -> keydown 'j'
          _.times 50, -> keydown 'l'
          # scrolls to end of line "5" (4th on screen but 0 based so 3)
          expect(editor.getCursorScreenPosition()).toEqual [3, 16]

  describe "motions with tabs", ->
    describe "the l keybinding", ->
      describe "as a motion", ->
        it "moves the cursor right, but not beyond end of line", ->
          # NOTE: This test handles edge case for scrolling
          # from beginning of line (through the tabs).
          # No other test failed when this functionality broke.
          _.times 9, -> keydown 'j'
          _.times 50, -> keydown 'l'
          # scrolls to end of line "10" (but 0 based so 9)
          expect(editor.getCursorScreenPosition()).toEqual [9, 38]
