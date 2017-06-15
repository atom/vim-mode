{Disposable, CompositeDisposable} = require 'event-kit'
StatusBarManager = require './status-bar-manager'
GlobalVimState = require './global-vim-state'
VimState = require './vim-state'
settings = require './settings'

module.exports =
  config: settings.config

  activate: (state) ->
    @disposables = new CompositeDisposable
    @globalVimState = new GlobalVimState
    @statusBarManager = new StatusBarManager

    @vimStates = new Set
    @vimStatesByEditor = new WeakMap

    @disposables.add atom.workspace.observeTextEditors (editor) =>
      return if editor.isMini() or @getEditorState(editor)

      vimState = new VimState(
        atom.views.getView(editor),
        @statusBarManager,
        @globalVimState
      )

      @vimStates.add(vimState)
      @vimStatesByEditor.set(editor, vimState)
      vimState.onDidDestroy => @vimStates.delete(vimState)

    @disposables.add atom.workspace.onDidChangeActivePaneItem @updateToPaneItem.bind(this)

    @disposables.add new Disposable =>
      @vimStates.forEach (vimState) -> vimState.destroy()

    # Protect against edge cases where after splitting a pane, input would be
    #  enabled in the original pane in command mode
    @disposables.add atom.workspace.onDidAddPane =>
      for paneItem in atom.workspace.getPaneItems()
        vimState = @vimStatesByEditor.get(paneItem)
        if vimState? and vimState.mode isnt 'insert'
          vimState.editorElement.component.setInputEnabled(false)
    @disposables.add atom.workspace.onDidDestroyPane =>
      for paneItem in atom.workspace.getPaneItems()
        vimState = @vimStatesByEditor.get(paneItem)
        if vimState? and vimState.mode isnt 'insert'
          vimState.editorElement.component.setInputEnabled(false)

  deactivate: ->
    @disposables.dispose()

  getGlobalState: ->
    @globalVimState

  getEditorState: (editor) ->
    @vimStatesByEditor.get(editor)

  consumeStatusBar: (statusBar) ->
    @statusBarManager.initialize(statusBar)
    @statusBarManager.attach()
    @disposables.add new Disposable =>
      @statusBarManager.detach()

  updateToPaneItem: (item) ->
    vimState = @getEditorState(item) if item?
    if vimState?
      vimState.updateStatusBar()
    else
      @statusBarManager.hide()

  provideVimMode: ->
    getGlobalState: @getGlobalState.bind(this)
    getEditorState: @getEditorState.bind(this)
