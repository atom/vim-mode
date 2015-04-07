VimCommandModeInputElement = require './vim-command-mode-input-element'

class ViewModel
  constructor: (@operation, opts={}) ->
    {@editor, @vimState} = @operation
    @view = new VimCommandModeInputElement().initialize(this, opts)
    @editor.commandModeInputView = @view
    @vimState.onDidFailToCompose => @view.remove()

  confirm: (view) ->
    @vimState.pushOperations(new Input(@view.value))

  cancel: (view) ->
    if @vimState.isOperatorPending()
      @vimState.pushOperations(new Input(''))

class Input
  constructor: (@characters) ->
  isComplete: -> true
  isRecordable: -> true

module.exports = {
  ViewModel, Input
}
