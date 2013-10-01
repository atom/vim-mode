{RootView} = require 'atom'

describe "VimMode", ->
  [editor] = []

  beforeEach ->
    window.rootView = new RootView
    rootView.open()
    rootView.simulateDomAttachment()
    atom.activatePackage('vim-mode', immediate: true)

    editor = rootView.getActiveView()
    editor.enableKeymap()

  describe "initialize", ->
    it "puts the editor in command-mode initially", ->
      expect(editor).toHaveClass 'vim-mode'
      expect(editor).toHaveClass 'command-mode'
