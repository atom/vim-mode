{WorkspaceView} = require 'atom'

describe "VimMode", ->
  [editorView] = []

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    atom.workspaceView.openSync()
    atom.workspaceView.simulateDomAttachment()

    waitsForPromise ->
      atom.packages.activatePackage('vim-mode')

    runs ->
      editorView = atom.workspaceView.getActiveView()
      editorView.enableKeymap()

  describe "initialize", ->
    it "puts the editor in command-mode initially", ->
      expect(editorView).toHaveClass 'vim-mode'
      expect(editorView).toHaveClass 'command-mode'
