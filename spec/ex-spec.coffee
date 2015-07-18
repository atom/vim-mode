fs = require 'fs-plus'
path = require 'path'
os = require 'os'
uuid = require 'node-uuid'
helpers = require './spec-helper'

describe "Ex", ->
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

  commandModeInputKeydown = (key, opts = {}) ->
    editor.commandModeInputView.editorElement.getModel().setText(key)

  submitCommandModeInputText = (text) ->
    commandEditor = editor.commandModeInputView.editorElement
    commandEditor.getModel().setText(text)
    atom.commands.dispatch(commandEditor, "core:confirm")

  beforeEach ->
    editor.setText("abc\ndef\nabc\ndef")

  describe "as a motion", ->
    beforeEach ->
      editor.setCursorBufferPosition([0, 0])

    it "moves the cursor to a specific line", ->
      keydown(':')
      submitCommandModeInputText '2'

      expect(editor.getCursorBufferPosition()).toEqual [1, 0]

    it "moves to the second address", ->
      keydown(':')
      submitCommandModeInputText '1,3'

      expect(editor.getCursorBufferPosition()).toEqual [2, 0]

    it "works with offsets", ->
      keydown(':')
      submitCommandModeInputText '2+1'
      expect(editor.getCursorBufferPosition()).toEqual [2, 0]

      keydown(':')
      submitCommandModeInputText '-2'
      expect(editor.getCursorBufferPosition()).toEqual [0, 0]

    it "doesn't move when the address is the current line", ->
      keydown(':')
      submitCommandModeInputText '.'
      expect(editor.getCursorBufferPosition()).toEqual [0, 0]

      keydown(':')
      submitCommandModeInputText ','
      expect(editor.getCursorBufferPosition()).toEqual [0, 0]

    it "moves to the last line", ->
      keydown(':')
      submitCommandModeInputText '$'
      expect(editor.getCursorBufferPosition()).toEqual [3, 0]

    it "moves to a mark's line", ->
      keydown('l')
      keydown('m')
      commandModeInputKeydown 'a'
      keydown('j')
      keydown(':')
      submitCommandModeInputText "'a"
      expect(editor.getCursorBufferPosition()).toEqual [0, 0]

    it "moves to a specified search", ->
      keydown(':')
      submitCommandModeInputText '/def'
      expect(editor.getCursorBufferPosition()).toEqual [1, 0]

      keydown(':')
      submitCommandModeInputText '?abc'
      expect(editor.getCursorBufferPosition()).toEqual [0, 0]

      editor.setCursorBufferPosition([3, 0])
      keydown(':')
      submitCommandModeInputText '/ef'
      expect(editor.getCursorBufferPosition()).toEqual [1, 0]

  describe "using command history", ->
    commandEditor = null

    beforeEach ->
      editor.setText("abc\ndef\nabc\ndef")
      keydown(':')
      submitCommandModeInputText('4')
      keydown(':')
      submitCommandModeInputText('-2')
      expect(editor.getCursorBufferPosition()).toEqual [1, 0]

      commandEditor = editor.commandModeInputView.editorElement

    it "allows searching history in the input field", ->
      keydown(':')
      atom.commands.dispatch(commandEditor, 'core:move-up')
      expect(commandEditor.getModel().getText()).toEqual('-2')
      atom.commands.dispatch(commandEditor, 'core:move-up')
      expect(commandEditor.getModel().getText()).toEqual('4')
      atom.commands.dispatch(commandEditor, 'core:move-down')
      expect(commandEditor.getModel().getText()).toEqual('-2')
      atom.commands.dispatch(commandEditor, 'core:move-down')
      expect(commandEditor.getModel().getText()).toEqual('')

    it "doesn't use the same history as the search", ->
      keydown('/')
      submitCommandModeInputText('/abc')
      keydown(':')
      atom.commands.dispatch(commandEditor, 'core:move-up')
      expect(commandEditor.getModel().getText()).toEqual('-2')

    it "integrates the search history for :/", ->
      keydown('/')
      submitCommandModeInputText('def')
      expect(editor.getCursorBufferPosition()).toEqual([3, 0])
      keydown(':')
      submitCommandModeInputText('//')
      expect(editor.getCursorBufferPosition()).toEqual([1, 0])

      keydown(':')
      submitCommandModeInputText('/ef/,/abc/+2')
      keydown('/')
      commandEditor = editor.commandModeInputView.editorElement
      atom.commands.dispatch(commandEditor, 'core:move-up')
      expect(commandEditor.getModel().getText()).toEqual('abc')
      atom.commands.dispatch(commandEditor, 'core:move-up')
      expect(commandEditor.getModel().getText()).not.toEqual('/ef')

  describe "the commands", ->
    [dir, dir2] = []
    projectPath = (fileName) -> path.join(dir, fileName)
    beforeEach ->
      dir = path.join(os.tmpdir(), "atom-spec-#{uuid.v4()}")
      dir2 = path.join(os.tmpdir(), "atom-spec-#{uuid.v4()}")
      fs.makeTreeSync(dir)
      fs.makeTreeSync(dir2)
      atom.project.setPaths([dir, dir2])

    afterEach ->
      fs.removeSync(dir)
      fs.removeSync(dir2)

    describe ":write", ->
      describe "when editing a new file", ->
        beforeEach ->
          editor.getBuffer().setText('abc\ndef')

        it "opens the save dialog", ->
          spyOn(atom, 'showSaveDialogSync')
          keydown(':')
          submitCommandModeInputText('write')
          expect(atom.showSaveDialogSync).toHaveBeenCalled()

        it "saves when a path is specified in the save dialog", ->
          filePath = projectPath('write-from-save-dialog')
          spyOn(atom, 'showSaveDialogSync').andReturn(filePath)
          spyOn(fs, 'writeFileSync').andCallThrough()
          keydown(':')
          submitCommandModeInputText('write')
          expect(fs.writeFileSync).toHaveBeenCalled()
          expect(fs.existsSync(filePath)).toBe(true)
          expect(fs.readFileSync(filePath, 'utf-8')).toEqual('abc\ndef')

        it "saves when a path is specified in the save dialog", ->
          spyOn(atom, 'showSaveDialogSync').andReturn(undefined)
          spyOn(fs, 'writeFileSync')
          keydown(':')
          submitCommandModeInputText('write')
          expect(fs.writeFileSync.calls.length).toBe(0)

      describe "when editing an existing file", ->
        filePath = ''
        i = 0

        beforeEach ->
          i++
          filePath = projectPath("write-#{i}")
          editor.getBuffer().setText('abc\ndef')
          editor.saveAs(filePath)

        it "saves the file", ->
          keydown(':')
          submitCommandModeInputText('write')
          expect(fs.existsSync(filePath)).toBe(true)
          expect(fs.readFileSync(filePath, 'utf-8')).toEqual('abc\ndef')
          expect(editor.isModified()).toBe(false)

          editor.getBuffer().setText('abc')
          keydown(':')
          submitCommandModeInputText('write')
          expect(fs.existsSync(filePath)).toBe(true)
          expect(fs.readFileSync(filePath, 'utf-8')).toEqual('abc')
          expect(editor.isModified()).toBe(false)

        describe "with a specified path", ->
          newPath = ''

          beforeEach ->
            newPath = path.relative(dir, "#{filePath}.new")
            editor.getBuffer().setText('abc')
            keydown(':')

          afterEach ->
            submitCommandModeInputText("write #{newPath}")
            newPath = path.resolve(dir, fs.normalize(newPath))
            expect(fs.existsSync(newPath)).toBe(true)
            expect(fs.readFileSync(newPath, 'utf-8')).toEqual('abc')
            expect(editor.isModified()).toBe(true)
            fs.removeSync(newPath)

          it "saves to the path", ->

          it "expands .", ->
            newPath = path.join('.', newPath)

          it "expands ..", ->
            newPath = path.join('..', newPath)

          it "expands ~", ->
            newPath = path.join('~', newPath)

        it "throws an error with more than one path", ->
          keydown(':')
          submitCommandModeInputText('write path1 path2')
          expect(atom.notifications.notifications[0].message).toEqual(
            'Command Error: Only one file name allowed'
          )

        describe "when the file already exists", ->
          existsPath = ''

          beforeEach ->
            existsPath = projectPath('write-exists')
            fs.writeFileSync(existsPath, 'abc')

          afterEach ->
            fs.removeSync(existsPath)

          it "throws an error if the file already exists", ->
            keydown(':')
            submitCommandModeInputText("write #{existsPath}")
            expect(atom.notifications.notifications[0].message).toEqual(
              'Command Error: File exists (add ! to override)'
            )
            expect(fs.readFileSync(existsPath, 'utf-8')).toEqual('abc')

          it "writes if forced with :write!", ->
            keydown(':')
            submitCommandModeInputText("write! #{existsPath}")
            expect(atom.notifications.notifications).toEqual([])
            expect(fs.readFileSync(existsPath, 'utf-8')).toEqual('abc\ndef')

    describe ":quit", ->
      pane = null
      beforeEach ->
        waitsForPromise ->
          pane = atom.workspace.getActivePane()
          spyOn(pane, 'destroyActiveItem')
            .andCallThrough()
          atom.workspace.open()

      it "closes the active pane item if not modified", ->
        keydown(':')
        submitCommandModeInputText('quit')
        expect(pane.destroyActiveItem).toHaveBeenCalled()

      describe "when the active pane item is modified", ->
        beforeEach ->
          editor.getBuffer().setText('def')

        it "opens the prompt to save", ->
          spyOn(pane, 'promptToSaveItem')
          keydown(':')
          submitCommandModeInputText('quit')
          expect(pane.promptToSaveItem).toHaveBeenCalled()

        it "doesn't close the active pane item if Cancel is clicked", ->
          spyOn(pane, 'promptToSaveItem').andReturn(false)
          keydown(':')
          submitCommandModeInputText('quit')
          expect(pane.promptToSaveItem).toHaveBeenCalled()
          expect(pane.getItems().length).toBe(1)

        it "closes the active pane item if Save or Don't Save is clicked", ->
          spyOn(pane, 'promptToSaveItem').andReturn(true)
          keydown(':')
          submitCommandModeInputText('quit')
          expect(pane.promptToSaveItem).toHaveBeenCalled()
          expect(pane.getItems().length).toBe(0)

    describe ":qall", ->
      beforeEach ->
        waitsForPromise ->
          atom.workspace.open().then -> atom.workspace.open()
            .then -> atom.workspace.open()

      it "closes the window", ->
        spyOn(atom, 'close')
        keydown(':')
        submitCommandModeInputText('qall')
        expect(atom.close).toHaveBeenCalled()

    describe ":tabnext", ->
      pane = null
      beforeEach ->
        waitsForPromise ->
          pane = atom.workspace.getActivePane()
          atom.workspace.open().then -> atom.workspace.open()
            .then -> atom.workspace.open()

      it "switches to the next tab", ->
        pane.activateItemAtIndex(1)
        keydown(':')
        submitCommandModeInputText('tabnext')
        expect(pane.getActiveItemIndex()).toBe(2)

      it "wraps around", ->
        pane.activateItemAtIndex(2)
        keydown(':')
        submitCommandModeInputText('tabnext')
        expect(pane.getActiveItemIndex()).toBe(0)

    describe ":tabprevious", ->
      pane = null
      beforeEach ->
        waitsForPromise ->
          pane = atom.workspace.getActivePane()
          atom.workspace.open().then -> atom.workspace.open()
            .then -> atom.workspace.open()

      it "switches to the previous tab", ->
        pane.activateItemAtIndex(1)
        keydown(':')
        submitCommandModeInputText('tabprevious')
        expect(pane.getActiveItemIndex()).toBe(0)

      it "wraps around", ->
        pane.activateItemAtIndex(0)
        keydown(':')
        submitCommandModeInputText('tabprevious')
        expect(pane.getActiveItemIndex()).toBe(2)

    describe ":update", ->
      it "acts as an alias to :write", ->
        spyOn(vimState.globalVimState.exCommands.commands.update, 'callback')
          .andCallThrough()
        spyOn(vimState.globalVimState.exCommands.commands.write, 'callback')
        keydown(':')
        submitCommandModeInputText('update')
        expect(vimState.globalVimState.exCommands.commands.write.callback)
          .toHaveBeenCalledWith(vimState.globalVimState.exCommands.commands
            .update.callback.calls[0].args[0])

    describe ":wall", ->
      it "saves all open files", ->
        spyOn(atom.workspace, 'saveAll')
        keydown(':')
        submitCommandModeInputText('wall')
        expect(atom.workspace.saveAll).toHaveBeenCalled()

    describe ":wq", ->
      beforeEach ->
        spyOn(vimState.globalVimState.exCommands.commands.write, 'callback')
          .andCallThrough()
        spyOn(vimState.globalVimState.exCommands.commands.quit, 'callback')

      it "writes the file, then quits", ->
        spyOn(atom, 'showSaveDialogSync').andReturn(projectPath('wq-1'))
        keydown(':')
        submitCommandModeInputText('wq')
        expect(vimState.globalVimState.exCommands.commands.write.callback)
          .toHaveBeenCalled()
        # Since `:wq` only calls `:quit` after `:write` is finished, we need to
        #  wait a bit for the `:quit` call to occur
        waitsFor((->
          vimState.globalVimState.exCommands.commands.quit.callback.wasCalled),
          "The :quit command should have been called", 100)

      it "doesn't quit when the file is new and no path is specified in the save dialog", ->
        spyOn(atom, 'showSaveDialogSync').andReturn(undefined)
        keydown(':')
        submitCommandModeInputText('wq')
        expect(vimState.globalVimState.exCommands.commands.write.callback)
          .toHaveBeenCalled()
        wasNotCalled = false
        # FIXME: This seems dangerous, but setTimeout somehow doesn't work.
        setImmediate((->
          wasNotCalled = not vimState.globalVimState.exCommands.commands.quit
            .callback.wasCalled))
        waitsFor((-> wasNotCalled), 100)

      it "passes the file name", ->
        keydown(':')
        submitCommandModeInputText('wq wq-2')
        expect(vimState.globalVimState.exCommands.commands.write.callback)
          .toHaveBeenCalled()
        expect(vimState.globalVimState.exCommands.commands.write.callback
          .calls[0].args[0].args).toEqual('wq-2')
        waitsFor((->
          vimState.globalVimState.exCommands.commands.quit.callback.wasCalled),
          "The :quit command should have been called", 100)

    describe ":xit", ->
      it "acts as an alias to :wq", ->
        spyOn(vimState.globalVimState.exCommands.commands.wq, 'callback')
        keydown(':')
        submitCommandModeInputText('xit')
        expect(vimState.globalVimState.exCommands.commands.wq.callback)
          .toHaveBeenCalled()

    describe ":exit", ->
      it "is an alias to :xit", ->
        spyOn(vimState.globalVimState.exCommands.commands.xit, 'callback')
        keydown(':')
        submitCommandModeInputText('exit')
        expect(vimState.globalVimState.exCommands.commands.xit.callback)
          .toHaveBeenCalled()

    describe ":xall", ->
      it "saves all open files and closes the window", ->
        spyOn(atom.workspace, 'saveAll')
        spyOn(atom, 'close')
        keydown(':')
        submitCommandModeInputText('xall')
        expect(atom.workspace.saveAll).toHaveBeenCalled()
        expect(atom.close).toHaveBeenCalled()
