VimState = require './vim-state'

module.exports =
  configDefaults:
    'commandModeInputViewFontSize': 11
    'startInInsertMode': false
    'useSmartcaseForSearch': false

  _initializeWorkspaceState: ->
    atom.workspace.vimState ||= {}
    atom.workspace.vimState.registers ||= {}
    atom.workspace.vimState.searchHistory ||= []

  activate: (state) ->
    @_initializeWorkspaceState()
    @editorObservation = atom.workspace.observeTextEditors (editor) =>
      return if editor.mini

      element = atom.views.getView(editor)
      element.classList.add('vim-mode')
      element.vimState = new VimState(element)

  deactivate: ->
    @editorObservation.dispose()
    for editor in atom.workspace.getTextEditors()
      element = atom.views.getView(editor)
      element.classList.remove("vim-mode")
      element.vimState?.destroy()
      delete element.vimState
