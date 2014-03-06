VimState = require './vim-state'

module.exports =
  configDefaults:
    'commandModeInputViewFontSize': 11

  activate: (state) ->
    atom.workspace.vimState ||= {}
    atom.workspace.vimState.registers ||= {}
    atom.workspaceView.eachEditorView (editorView) =>
      return unless editorView.attached

      editorView.addClass('vim-mode')
      editorView.vimState = new VimState(editorView)
