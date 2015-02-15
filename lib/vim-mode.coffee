{Disposable, CompositeDisposable} = require 'event-kit'
StatusBarManager = require './status-bar-manager'
GlobalVimState = require './global-vim-state'
VimState = require './vim-state'

module.exports =
  config:
    startInInsertMode:
      type: 'boolean'
      default: false
    useSmartcaseForSearch:
      type: 'boolean'
      default: false
    wrapLeftRightMotion:
      type: 'boolean'
      default: false

  activate: (state) ->
    @disposables = new CompositeDisposable
    globalVimState = new GlobalVimState
    @statusBarManager = new StatusBarManager
    vimStates = new WeakMap

    @disposables.add atom.workspace.observeTextEditors (editor) =>
      return if editor.mini

      element = atom.views.getView(editor)

      if not vimStates.get(editor)
        vimState = new VimState(
          element,
          @statusBarManager,
          globalVimState
        )

        vimStates.set(editor, vimState)

        @disposables.add new Disposable =>
          vimState.destroy()

  deactivate: ->
    @disposables.dispose()

  consumeStatusBar: (statusBar) ->
    @statusBarManager.initialize(statusBar)
    @statusBarManager.attach()
    @disposables.add new Disposable =>
      @statusBarManager.detach()
