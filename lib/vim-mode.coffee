{CompositeDisposable} = require 'event-kit'
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
      element.classList.add('vim-mode')
      element.vimState = new VimState(element, statusBarManager, globalVimState)

  deactivate: ->
    @disposables.dispose()

    for editor in atom.workspace.getTextEditors()
      element = atom.views.getView(editor)
      element.classList.remove("vim-mode")
      element.vimState?.destroy()
      delete element.vimState
