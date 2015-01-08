{Workspace} = require 'atom'

describe "VimMode", ->
  [editor, editorElement] = []

  beforeEach ->
    atom.workspace = new Workspace

    waitsForPromise ->
      atom.workspace.open()

    waitsForPromise ->
      atom.packages.activatePackage('vim-mode')

    runs ->
      editor = atom.workspace.getActiveTextEditor()
      editorElement = atom.views.getView(editor)

  describe ".activate", ->
    it "puts the editor in command-mode initially by default", ->
      expect(editorElement.classList.contains('vim-mode')).toBe(true)
      expect(editorElement.classList.contains('command-mode')).toBe(true)

    it "doesn't register duplicate command listeners for editors", ->
      editor.setText("12345")
      editor.setCursorBufferPosition([0, 0])

      pane = atom.workspace.getActivePane()
      newPane = pane.splitRight()
      pane.removeItem(editor)
      newPane.addItem(editor)

      atom.commands.dispatch(editorElement, "vim-mode:move-right")
      expect(editor.getCursorBufferPosition()).toEqual([0, 1])

  describe ".deactivate", ->
    it "removes the vim classes from the editor", ->
      atom.packages.deactivatePackage('vim-mode')
      expect(editorElement.classList.contains("vim-mode")).toBe(false)
      expect(editorElement.classList.contains("command-mode")).toBe(false)

    it "removes the vim commands from the editor element", ->
      vimCommands = ->
        atom.commands.findCommands(target: editorElement).filter (cmd) ->
          cmd.name.startsWith("vim-mode:")

      expect(vimCommands().length).toBeGreaterThan(0)
      atom.packages.deactivatePackage('vim-mode')
      expect(vimCommands().length).toBe(0)
