VimNormalModeInputElement = require './vim-normal-mode-input-element'

class ViewModel
  constructor: (@operation, opts={}) ->
    {@editor, @vimState} = @operation
    @view = new VimNormalModeInputElement().initialize(this, atom.views.getView(@editor), opts)
    @editor.normalModeInputView = @view
    @vimState.onDidFailToCompose => @view.remove()

  confirm: (view) ->
    @vimState.pushOperations(new Input(@view.value))

  cancel: (view) ->
    if @vimState.isOperatorPending()
      @vimState.pushOperations(new Input(''))
    delete @editor.normalModeInputView

class Input
  constructor: (@characters) ->
  isComplete: -> true
  isRecordable: -> true

module.exports = {
  ViewModel, Input
}
