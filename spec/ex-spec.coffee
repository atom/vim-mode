fs = require 'fs-plus'
path = require 'path'
os = require 'os'
uuid = require 'node-uuid'
helpers = require './spec-helper'
ExMode = require '../lib/motions/ex-motion'

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
      editor.setText("abc\ndef\nabc\ndef")

  keydown = (key, options={}) ->
    options.element ?= editorElement
    helpers.keydown(key, options)

  commandModeInputKeydown = (key, opts = {}) ->
    editor.commandModeInputView.editorElement.getModel().setText(key)

  submitCommandModeInputText = (text) ->
    commandEditor = editor.commandModeInputView.editorElement
    commandEditor.getModel().setText(text)
    atom.commands.dispatch(commandEditor, "core:confirm")

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

  describe "command parsing", ->
    ex = null
    beforeEach ->
      ex = new ExMode(editor, vimState)

    it "parses a simple command without a range or arguments", ->
      spyOn(vimState.globalVimState.exCommands.commands.write, 'callback')
      parsed = ex.parse('write', editor.getCursors()[0])
      parsed[1]()
      expect(vimState.globalVimState.exCommands.commands.write.callback)
        .toHaveBeenCalled()

    it "matches the beginning of a command against that command", ->
      spyOn(vimState.globalVimState.exCommands.commands.write, 'callback')
      parsed = ex.parse('writ', editor.getCursors()[0])
      parsed[1]()
      expect(vimState.globalVimState.exCommands.commands.write.callback)
        .toHaveBeenCalled()
      parsed = ex.parse('w', editor.getCursors()[0])
      parsed[1]()
      expect(vimState.globalVimState.exCommands.commands.write.callback)
        .toHaveBeenCalled()

    it "executes the command with the highest priority when multiple match an input", ->
      spyOn(vimState.globalVimState.exCommands.commands.substitute, 'callback')
      spyOn(vimState.globalVimState.exCommands.commands.split, 'callback')
      parsed = ex.parse('s', editor.getCursors()[0])
      parsed[1]()
      expect(vimState.globalVimState.exCommands.commands.substitute.callback)
        .toHaveBeenCalled()
      expect(vimState.globalVimState.exCommands.commands.split.callback
        .calls.length).toBe(0)

    it "parses a command with a range", ->
      spyOn(vimState.globalVimState.exCommands.commands.delete, 'callback')
      parsed = ex.parse('1,3delete', editor.getCursors()[0])
      parsed[1]()
      expect(vimState.globalVimState.exCommands.commands.delete.callback)
        .toHaveBeenCalled()
      expect(parsed[0]).toEqual([0, 2])

    it "parses a command with an argument when separated by a space", ->
      spyOn(vimState.globalVimState.exCommands.commands.edit, 'callback')
      parsed = ex.parse('edit test-file', editor.getCursors()[0])
      parsed[1]()
      expect(vimState.globalVimState.exCommands.commands.edit.callback)
        .toHaveBeenCalled()
      expect(parsed[2]).toEqual('test-file')

    it "parses a command with an argument when starting with a non-alphabetic character", ->
      spyOn(vimState.globalVimState.exCommands.commands.edit, 'callback')
      parsed = ex.parse('edit/tmp/test-file', editor.getCursors()[0])
      parsed[1]()
      expect(vimState.globalVimState.exCommands.commands.edit.callback)
        .toHaveBeenCalled()
      expect(parsed[2]).toEqual('/tmp/test-file')

    it "parses a complex command into range, command and arguments", ->
      spyOn(vimState.globalVimState.exCommands.commands.substitute, 'callback')
      parsed = ex.parse('1,3s/a/b/g', editor.getCursors()[0])
      parsed[1]()
      expect(vimState.globalVimState.exCommands.commands.substitute.callback)
        .toHaveBeenCalled()
      expect(parsed[0]).toEqual([0, 2])
      expect(parsed[2]).toEqual('/a/b/g')

    it "ignores leading blanks and colons", ->
      spyOn(vimState.globalVimState.exCommands.commands.write, 'callback')
      parsed = ex.parse(' ::: \t : write', editor.getCursors()[0])
      parsed[1]()
      expect(vimState.globalVimState.exCommands.commands.write.callback)
        .toHaveBeenCalled()

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

    describe ":tabclose", ->
      it "acts as an alias to :quit", ->
        spyOn(vimState.globalVimState.exCommands.commands.tabclose, 'callback')
          .andCallThrough()
        spyOn(vimState.globalVimState.exCommands.commands.quit, 'callback')
        keydown(':')
        submitCommandModeInputText('tabclose')
        expect(vimState.globalVimState.exCommands.commands.quit.callback)
          .toHaveBeenCalledWith(vimState.globalVimState.exCommands.commands
            .tabclose.callback.calls[0].args[0])

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

    describe ":edit", ->
      describe "without a file name", ->
        it "reloads the file from the disk", ->
          filePath = projectPath("edit-1")
          editor.getBuffer().setText('abc')
          editor.saveAs(filePath)
          fs.writeFileSync(filePath, 'def')
          keydown(':')
          submitCommandModeInputText('edit')
          # Reloading takes a bit
          waitsFor((-> editor.getText() is 'def'),
            "the editor's content to change", 50)

        it "doesn't reload when the file has been modified", ->
          filePath = projectPath("edit-2")
          editor.getBuffer().setText('abc')
          editor.saveAs(filePath)
          editor.getBuffer().setText('abcd')
          fs.writeFileSync(filePath, 'def')
          keydown(':')
          submitCommandModeInputText('edit')
          expect(atom.notifications.notifications[0].message).toEqual(
            'Command Error: No write since last change (add ! to override)')
          isntDef = false
          setImmediate(-> isntDef = editor.getText() isnt 'def')
          waitsFor((-> isntDef), "the editor's content not to change", 50)

        it "reloads when the file has been modified and it is forced", ->
          filePath = projectPath("edit-3")
          editor.getBuffer().setText('abc')
          editor.saveAs(filePath)
          editor.getBuffer().setText('abcd')
          fs.writeFileSync(filePath, 'def')
          keydown(':')
          submitCommandModeInputText('edit!')
          expect(atom.notifications.notifications.length).toBe(0)
          waitsFor((-> editor.getText() is 'def')
            "the editor's content to change", 50)

        it "throws an error when editing a new file", ->
          editor.getBuffer().reload()
          keydown(':')
          submitCommandModeInputText('edit')
          expect(atom.notifications.notifications[0].message).toEqual(
            'Command Error: No file name')
          keydown(':')
          submitCommandModeInputText('edit!')
          expect(atom.notifications.notifications[1].message).toEqual(
            'Command Error: No file name')

      describe "with a file name", ->
        beforeEach ->
          spyOn(atom.workspace, 'open')
          editor.getBuffer().reload()

        it "opens the specified path", ->
          filePath = projectPath('edit-new-test')
          keydown(':')
          submitCommandModeInputText("edit #{filePath}")
          expect(atom.workspace.open).toHaveBeenCalledWith(filePath)

        it "allows for spaces in file names if escaped with \\", ->
          filePath = projectPath('edit\\ new\\ test')
          keydown(':')
          submitCommandModeInputText(
            "edit #{projectPath('edit\\ new\\ test')}")
          expect(atom.workspace.open).toHaveBeenCalledWith(
            projectPath('edit new test'))

        it "opens a relative path", ->
          keydown(':')
          submitCommandModeInputText('edit edit-relative-test')
          expect(atom.workspace.open).toHaveBeenCalledWith(
            projectPath('edit-relative-test'))

        it "throws an error if trying to open more than one file", ->
          keydown(':')
          submitCommandModeInputText('edit edit-new-test-1 edit-new-test-2')
          expect(atom.workspace.open.callCount).toBe(0)
          expect(atom.notifications.notifications[0].message).toEqual(
            'Command Error: Only one file name allowed')

    describe ":tabedit", ->
      it "acts as an alias to :edit if supplied with a path", ->
        spyOn(vimState.globalVimState.exCommands.commands.tabedit, 'callback')
          .andCallThrough()
        spyOn(vimState.globalVimState.exCommands.commands.edit, 'callback')
        keydown(':')
        submitCommandModeInputText('tabedit tabedit-test')
        expect(vimState.globalVimState.exCommands.commands.edit.callback)
          .toHaveBeenCalledWith(vimState.globalVimState.exCommands.commands
            .tabedit.callback.calls[0].args[0])
      it "acts as an alias to :tabnew if not supplied with a path", ->
        spyOn(vimState.globalVimState.exCommands.commands.tabedit, 'callback')
          .andCallThrough()
        spyOn(vimState.globalVimState.exCommands.commands.tabnew, 'callback')
        keydown(':')
        submitCommandModeInputText('tabedit  ')
        expect(vimState.globalVimState.exCommands.commands.tabnew.callback)
          .toHaveBeenCalledWith(vimState.globalVimState.exCommands.commands
            .tabedit.callback.calls[0].args[0])

    describe ":tabnew", ->
      it "opens a new tab", ->
        spyOn(atom.workspace, 'open')
        keydown(':')
        submitCommandModeInputText('tabnew')
        expect(atom.workspace.open).toHaveBeenCalled()

    describe ":split", ->
      it "splits the current file upwards", ->
        pane = atom.workspace.getActivePane()
        spyOn(pane, 'splitUp').andCallThrough()
        filePath = projectPath('split')
        editor.saveAs(filePath)
        keydown(':')
        submitCommandModeInputText('split')
        expect(pane.splitUp).toHaveBeenCalled()
        # FIXME: Should test whether the new pane contains a TextEditor
        #        pointing to the same path

    describe ":new", ->
      it "splits a new file upwards", ->
        pane = atom.workspace.getActivePane()
        spyOn(pane, 'splitUp').andCallThrough()
        keydown(':')
        submitCommandModeInputText('new')
        expect(pane.splitUp).toHaveBeenCalled()
        # FIXME: Should test whether the new pane contains an empty file

    describe ":vsplit", ->
      it "splits the current file to the left", ->
        pane = atom.workspace.getActivePane()
        spyOn(pane, 'splitLeft').andCallThrough()
        filePath = projectPath('vsplit')
        editor.saveAs(filePath)
        keydown(':')
        submitCommandModeInputText('vsplit')
        expect(pane.splitLeft).toHaveBeenCalled()
        # FIXME: Should test whether the new pane contains a TextEditor
        #        pointing to the same path

    describe ":vnew", ->
      it "splits a new file to the left", ->
        pane = atom.workspace.getActivePane()
        spyOn(pane, 'splitLeft').andCallThrough()
        keydown(':')
        submitCommandModeInputText('vnew')
        expect(pane.splitLeft).toHaveBeenCalled()
        # FIXME: Should test whether the new pane contains an empty file

    describe ":delete", ->
      beforeEach ->
        editor.setText('abc\ndef\nghi\njkl')
        editor.setCursorBufferPosition([2, 0])

      it "deletes the current line", ->
        keydown(':')
        submitCommandModeInputText('delete')
        expect(editor.getText()).toEqual('abc\ndef\njkl')

      it "deletes the lines in the given range", ->
        keydown(':')
        submitCommandModeInputText('1,2delete')
        expect(editor.getText()).toEqual('ghi\njkl')

        editor.setText('abc\ndef\nghi\njkl')
        editor.setCursorBufferPosition([1, 1])
        keydown(':')
        submitCommandModeInputText(',/k/delete')
        expect(editor.getText()).toEqual('abc\n')

      it "undos deleting several lines at once", ->
        keydown(':')
        submitCommandModeInputText('-1,delete')
        expect(editor.getText()).toEqual('abc\njkl')
        keydown('u')
        expect(editor.getText()).toEqual('abc\ndef\nghi\njkl')

    describe ":substitute", ->
      beforeEach ->
        editor.setText('abcaABC\ndefdDEF\nabcaABC')
        editor.setCursorBufferPosition([0, 0])

      it "replaces a character on the current line", ->
        keydown(':')
        submitCommandModeInputText(':substitute /a/x')
        expect(editor.getText()).toEqual('xbcaABC\ndefdDEF\nabcaABC')

      it "doesn't need a space before the arguments", ->
        keydown(':')
        submitCommandModeInputText(':substitute/a/x')
        expect(editor.getText()).toEqual('xbcaABC\ndefdDEF\nabcaABC')

      it "respects modifiers passed to it", ->
        keydown(':')
        submitCommandModeInputText(':substitute/a/x/g')
        expect(editor.getText()).toEqual('xbcxABC\ndefdDEF\nabcaABC')

        keydown(':')
        submitCommandModeInputText(':substitute/a/x/gi')
        expect(editor.getText()).toEqual('xbcxxBC\ndefdDEF\nabcaABC')

      it "replaces on multiple lines", ->
        keydown(':')
        submitCommandModeInputText(':%substitute/abc/ghi')
        expect(editor.getText()).toEqual('ghiaABC\ndefdDEF\nghiaABC')

        keydown(':')
        submitCommandModeInputText(':%substitute/abc/ghi/ig')
        expect(editor.getText()).toEqual('ghiaghi\ndefdDEF\nghiaghi')

      it "can't be delimited by letters or \\", ->
        keydown(':')
        submitCommandModeInputText(':substitute nanxngi')
        expect(atom.notifications.notifications[0].message).toEqual(
          "Command Error: Regular expressions can't be delimited by letters")
        expect(editor.getText()).toEqual('abcaABC\ndefdDEF\nabcaABC')

        keydown(':')
        submitCommandModeInputText(':substitute\\a\\x\\gi')
        expect(atom.notifications.notifications[1].message).toEqual(
          "Command Error: Regular expressions can't be delimited by \\")
        expect(editor.getText()).toEqual('abcaABC\ndefdDEF\nabcaABC')

      describe "case sensitivity", ->
        describe "respects the smartcase setting", ->
          beforeEach ->
            editor.setText('abcaABC\ndefdDEF\nabcaABC')

          it "uses case sensitive search if smartcase is off and the pattern is lowercase", ->
            atom.config.set('vim-mode.useSmartcaseForSearch', false)
            keydown(':')
            submitCommandModeInputText(':substitute/abc/ghi/g')
            expect(editor.getText()).toEqual('ghiaABC\ndefdDEF\nabcaABC')

          it "uses case sensitive search if smartcase is off and the pattern is uppercase", ->
            editor.setText('abcaABC\ndefdDEF\nabcaABC')
            keydown(':')
            submitCommandModeInputText(':substitute/ABC/ghi/g')
            expect(editor.getText()).toEqual('abcaghi\ndefdDEF\nabcaABC')

          it "uses case insensitive search if smartcase is on and the pattern is lowercase", ->
            editor.setText('abcaABC\ndefdDEF\nabcaABC')
            atom.config.set('vim-mode.useSmartcaseForSearch', true)
            keydown(':')
            submitCommandModeInputText(':substitute/abc/ghi/g')
            expect(editor.getText()).toEqual('ghiaghi\ndefdDEF\nabcaABC')

          it "uses case sensitive search if smartcase is on and the pattern is uppercase", ->
            editor.setText('abcaABC\ndefdDEF\nabcaABC')
            keydown(':')
            submitCommandModeInputText(':substitute/ABC/ghi/g')
            expect(editor.getText()).toEqual('abcaghi\ndefdDEF\nabcaABC')

        describe "\\c and \\C in the pattern", ->
          beforeEach ->
            editor.setText('abcaABC\ndefdDEF\nabcaABC')

          it "uses case insensitive search if smartcase is off and \c is in the pattern", ->
            atom.config.set('vim-mode.useSmartcaseForSearch', false)
            keydown(':')
            submitCommandModeInputText(':substitute/abc\\c/ghi/g')
            expect(editor.getText()).toEqual('ghiaghi\ndefdDEF\nabcaABC')

          it "doesn't matter where in the pattern \\c is", ->
            atom.config.set('vim-mode.useSmartcaseForSearch', false)
            keydown(':')
            submitCommandModeInputText(':substitute/a\\cbc/ghi/g')
            expect(editor.getText()).toEqual('ghiaghi\ndefdDEF\nabcaABC')

          it "uses case sensitive search if smartcase is on, \\C is in the pattern and the pattern is lowercase", ->
            atom.config.set('vim-mode.useSmartcaseForSearch', true)
            keydown(':')
            submitCommandModeInputText(':substitute/a\\Cbc/ghi/g')
            expect(editor.getText()).toEqual('ghiaABC\ndefdDEF\nabcaABC')

          it "overrides \\C with \\c if \\C comes first", ->
            atom.config.set('vim-mode.useSmartcaseForSearch', true)
            keydown(':')
            submitCommandModeInputText(':substitute/a\\Cb\\cc/ghi/g')
            expect(editor.getText()).toEqual('ghiaghi\ndefdDEF\nabcaABC')

          it "overrides \\C with \\c if \\c comes first", ->
            atom.config.set('vim-mode.useSmartcaseForSearch', true)
            keydown(':')
            submitCommandModeInputText(':substitute/a\\cb\\Cc/ghi/g')
            expect(editor.getText()).toEqual('ghiaghi\ndefdDEF\nabcaABC')

          it "overrides an appended /i flag with \\C", ->
            atom.config.set('vim-mode.useSmartcaseForSearch', true)
            keydown(':')
            submitCommandModeInputText(':substitute/ab\\Cc/ghi/gi')
            expect(editor.getText()).toEqual('ghiaABC\ndefdDEF\nabcaABC')

      describe "capturing groups", ->
        beforeEach ->
          editor.setText('abcaABC\ndefdDEF\nabcaABC')

        it "replaces \\1 with the first group", ->
          keydown(':')
          submitCommandModeInputText(':substitute/bc(.{2})/X\\1X')
          expect(editor.getText()).toEqual('aXaAXBC\ndefdDEF\nabcaABC')

        it "replaces multiple groups", ->
          keydown(':')
          submitCommandModeInputText(':substitute/a([a-z]*)aA([A-Z]*)/X\\1XY\\2Y')
          expect(editor.getText()).toEqual('XbcXYBCY\ndefdDEF\nabcaABC')

        it "replaces \\0 with the entire match", ->
          keydown(':')
          submitCommandModeInputText(':substitute/ab(ca)AB/X\\0X')
          expect(editor.getText()).toEqual('XabcaABXC\ndefdDEF\nabcaABC')
