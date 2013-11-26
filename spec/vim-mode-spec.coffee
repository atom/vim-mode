{RootView} = require 'atom'

describe "VimMode", ->
  [editor] = []

  beforeEach ->
    atom.rootView = new RootView
    atom.rootView.openSync()
    atom.rootView.simulateDomAttachment()
    atom.packages.activatePackage('vim-mode', immediate: true)

    editor = atom.rootView.getActiveView()
    editor.enableKeymap()

  describe "initialize", ->
    it "puts the editor in command-mode initially", ->
      expect(editor).toHaveClass 'vim-mode'
      expect(editor).toHaveClass 'command-mode'
