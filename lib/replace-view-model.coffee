VimCommandModeInputView = require './vim-command-mode-input-view'

module.exports =

# This is the view model for a Replace operator. It is an implementation
# detail of the same, and is tested via the use of the `r` keybinding
# in operators-spec.coffee.
class ReplaceViewModel
  constructor: (@replaceOperator) ->
    @editorView = @replaceOperator.editorView
    @vimState   = @replaceOperator.state

    @view = new VimCommandModeInputView(@, class: 'replace', hidden: true, singleChar: true)
    @editorView.editor.commandModeInputView = @view

  confirm: (view) ->
    @char = @view.value
    @editorView.trigger('vim-mode:replace-complete')
