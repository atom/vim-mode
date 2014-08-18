{WorkspaceView} = require 'atom'

describe "VimMode", ->
  [editorView] = []

  beforeEach ->
    atom.workspaceView = new WorkspaceView

    waitsForPromise ->
      atom.workspace.open()

    runs ->
      atom.workspaceView.simulateDomAttachment()

    waitsForPromise ->
      atom.packages.activatePackage('vim-mode')

    runs ->
      editorView = atom.workspaceView.getActiveView()
      editorView.enableKeymap()

  describe "initialize", ->
    it "puts the editor in command-mode initially by default", ->
      expect(editorView).toHaveClass 'vim-mode'
      expect(editorView).toHaveClass 'command-mode'

  describe 'deactivate', ->
    beforeEach ->
      atom.packages.deactivatePackage('vim-mode')

      waitsForPromise ->
        atom.packages.activatePackage('vim-mode')

      runs ->
        editorView = atom.workspaceView.getActiveView()
        editorView.enableKeymap()

    it 'clears the vim namespaced events from the editorView', ->
      handlers = editorView.handlers()
      expect(handlers['vim-mode:move-down'].length).toEqual(1)
