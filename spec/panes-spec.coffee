helpers = require './spec-helper'

describe "Panes", ->
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

  describe "switch panes", ->
    paneContainer = null
    beforeEach ->
      paneContainer = atom.views.getView(atom.workspace.paneContainer)
      editor.setText("abcde\n")

    describe "the ctrl-w l keybinding", ->
      beforeEach ->
        spyOn(paneContainer, 'focusPaneViewOnRight')

      it "focuses the pane on the right", ->
        keydown('w', ctrl: true)
        keydown('l')

        expect(paneContainer.focusPaneViewOnRight).toHaveBeenCalled()

    describe "the ctrl-w h keybinding", ->
      beforeEach ->
        spyOn(paneContainer, 'focusPaneViewOnLeft')

      it "focuses the pane on the left", ->
        keydown('w', ctrl: true)
        keydown('h')

        expect(paneContainer.focusPaneViewOnLeft).toHaveBeenCalled()

    describe "the ctrl-w j keybinding", ->
      beforeEach ->
        spyOn(paneContainer, 'focusPaneViewBelow')

      it "focuses the pane on the below", ->
        keydown('w', ctrl: true)
        keydown('j')

        expect(paneContainer.focusPaneViewBelow).toHaveBeenCalled()

    describe "the ctrl-w k keybinding", ->
      beforeEach ->
        spyOn(paneContainer, 'focusPaneViewAbove')

      it "focuses the pane on the above", ->
        keydown('w', ctrl: true)
        keydown('k')

        expect(paneContainer.focusPaneViewAbove).toHaveBeenCalled()
