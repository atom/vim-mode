VimState = require './vim-state'

module.exports =
  configDefaults:
    'commandModeInputViewFontSize': 11
    'startInInsertMode': false

  _initializeWorkspaceState: ->
    atom.workspace.vimState ||= {}
    atom.workspace.vimState.registers ||= {}
    atom.workspace.vimState.searchHistory ||= []

  activate: (state) ->
    @_initializeWorkspaceState()
    atom.workspaceView.eachEditorView (editorView) =>
      return unless editorView.attached
      return if editorView.mini

      editorView.addClass('vim-mode')
      editorView.vimState = new VimState(editorView)

  deactivate: ->
    atom.workspaceView?.eachEditorView (editorView) =>
      editorView.off('.vim-mode')
