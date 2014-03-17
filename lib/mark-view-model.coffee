VimCommandModeInputView = require './vim-command-mode-input-view'

module.exports =

# This is the view model for a Mark operator. It is an implementation
# detail of the same, and is tested via the use of the `m` keybinding
# in operators-spec.coffee.
class MarkViewModel
  constructor: (@markOperator) ->
    @editorView = @markOperator.editorView
    @vimState   = @markOperator.state

    @view = new VimCommandModeInputView(@, class: 'mark', hidden: true, singleChar: true)
    @editorView.editor.commandModeInputView = @view

  confirm: (view) ->
    @char = @view.value
    @editorView.trigger('vim-mode:mark-complete')
