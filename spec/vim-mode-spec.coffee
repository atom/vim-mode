{Workspace} = require 'atom'

describe "VimMode", ->
  editorElement = null

  beforeEach ->
    atom.workspace = new Workspace

    waitsForPromise ->
      atom.workspace.open()

    waitsForPromise ->
      atom.packages.activatePackage('vim-mode')

    runs ->
      editorElement = atom.views.getView(atom.workspace.getActiveTextEditor())

  describe ".activate", ->
    it "puts the editor in command-mode initially by default", ->
      expect(editorElement.classList.contains('vim-mode')).toBe(true)
      expect(editorElement.classList.contains('command-mode')).toBe(true)

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
