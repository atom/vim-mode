{Disposable, CompositeDisposable, Emitter} = require 'event-kit'
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

  emitter: new Emitter

  activate: (state) ->
    @disposables = new CompositeDisposable
    @editorStateMap = {}
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

      @editorStateMap[editor.id] = vimState
      @emitter.emit 'did-attach', vimState

      stateDisposable = new Disposable =>
        delete @editorStateMap[vimState.editor.id]
        vimState.destroy()

      @disposables.add stateDisposable
      editor.onDidDestroy -> stateDisposable.dispose()

    version = require('../package.json').version
    @disposables.add atom.services.provide "vim-mode", version,
      getStateForEditor: @getStateForEditor.bind(this)
      onDidAttach: @onDidAttach.bind(this)
      observeVimStates: @observeVimStates.bind(this)

  deactivate: ->
    @disposables.dispose()

  getStateForEditor: (editor) -> @editorStateMap[editor.id]

  onDidAttach: (callback) -> @emitter.on 'did-attach', callback

  observeVimStates: (callback) ->
    for id, vimState of @editorStateMap
        callback(vimState)
    @onDidAttach(callback)

module.exports.Motions = require './motions'
module.exports.Operators = require './operators'
module.exports.ViewModels = require './view-models/view-model'
module.exports.ViewModels.VimCommandModeInputView =
  require './view-models/vim-command-mode-input-view'
