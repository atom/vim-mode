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
