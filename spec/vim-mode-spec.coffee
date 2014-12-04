{Workspace} = require 'atom'

describe "VimMode", ->
  editorElement = null
  vimMode = null

  beforeEach ->
    atom.workspace = new Workspace

    waitsForPromise ->
      atom.workspace.open()

    waitsForPromise ->
      atom.packages.activatePackage('vim-mode')

    runs ->
      editorElement = atom.views.getView(atom.workspace.getActiveTextEditor())
      vimMode = atom.packages.getLoadedPackage('vim-mode').mainModule

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

  describe ".getStateForEditor", ->
    it "returns VimState for existing editor", ->
      state = vimMode.getStateForEditor(atom.workspace.getActiveTextEditor())
      expect(state?.pushOperations).toBeDefined()

  describe ".onDidAttach", ->
    it "is invoked with VimState for created editor", ->
      done = off
      vimMode.onDidAttach (state) ->
        expect(state.pushOperations).toBeDefined()
        done = on
      atom.workspace.open()
      waitsFor -> done

  describe ".observeVimStates", ->
    it "invokes callback for existing and newly created VimStates", ->
      done = 0
      vimMode.observeVimStates (state) ->
        expect(state.pushOperations).toBeDefined()
        done = done + 1
      atom.workspace.open()
      waitsFor -> done == 2
