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

  activate: (state) ->
    @disposables = new CompositeDisposable
    globalVimState = new GlobalVimState
    statusBarManager = new StatusBarManager

    @disposables.add statusBarManager.initialize()
    @disposables.add atom.workspace.observeTextEditors (editor) =>
      return if editor.mini

      element = atom.views.getView(editor)

      vimState = new VimState(
        element,
        statusBarManager,
        globalVimState
      )

      @disposables.add new Disposable =>
        vimState.destroy()

  deactivate: ->
    @disposables.dispose()
