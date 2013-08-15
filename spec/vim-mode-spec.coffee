RootView = require 'root-view'
Keymap = require 'keymap'

fdescribe "VimMode", ->
  [editor, originalKeymap] = []

  beforeEach ->
    originalKeymap = window.keymap
    window.keymap = new Keymap

    window.rootView = new RootView
    rootView.open()
    rootView.simulateDomAttachment()
    atom.activatePackage('vim-mode', immediate: true)

    editor = rootView.getActiveView()
    editor.enableKeymap()

  afterEach ->
    window.keymap = originalKeymap

  describe "initialize", ->
    it "puts the editor in command-mode initially", ->
      expect(editor).toHaveClass 'vim-mode'
      expect(editor).toHaveClass 'command-mode'
