VimState = require './vim-state'
JumpList = require './jumplist'

module.exports =
  configDefaults:
    'commandModeInputViewFontSize': 11
    'startInInsertMode': false
    'useSmartcaseForSearch': false

  _initializeWorkspaceState: ->
    atom.workspace.vimState ||= {}
    atom.workspace.vimState.registers ||= {}
    atom.workspace.vimState.searchHistory ||= []
    atom.workspace.vimState.jumpList ||= new JumpList()

  activate: (state) ->
    @_initializeWorkspaceState()
    atom.workspaceView.eachEditorView (editorView) =>
      return unless editorView.attached
      return if editorView.mini

      editorView.addClass('vim-mode')
      editorView.vimState = new VimState(editorView)

  deactivate: ->
    atom.workspaceView?.eachEditorView (editorView) =>
      editorView.removeClass("vim-mode")
      editorView.vimState?.destroy()
      delete editorView.vimState
