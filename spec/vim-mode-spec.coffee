{WorkspaceView} = require 'atom'

describe "VimMode", ->
  [editor] = []

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    atom.workspaceView.openSync()
    atom.workspaceView.simulateDomAttachment()
    atom.packages.activatePackage('vim-mode', immediate: true)

    editor = atom.workspaceView.getActiveView()
    editor.enableKeymap()

  describe "initialize", ->
    it "puts the editor in command-mode initially", ->
      expect(editor).toHaveClass 'vim-mode'
      expect(editor).toHaveClass 'command-mode'
