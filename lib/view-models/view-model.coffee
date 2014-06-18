VimCommandModeInputView = require './vim-command-mode-input-view'

# Public: Base class for all view models; a view model
#         is the model attached to a VimCommandModeInputView
#         which is used when a given operator, motion
#         needs extra keystroke.
#
# Ivars:
#
#   @completionCommand - if set will automatically be triggered on the editorView
#                        when the `confirm` method is called on the view model
#
#   @value - automatically set to the value of typed into the `VimCommandModeInputView`
#            when the `confirm` method is called
#
class ViewModel
  # Public: Override this in subclasses for custom initialization
  #
  # operator - An operator, motion, prefix, etc with `@editorView` and `@state` set
  #
  # opts - the options to be passed to `VimCommandModeInputView`. Possible options are:
  #
  #            - class {String} - the class of the view to be added to the bottom of the screen
  #
  #            - hidden {Boolean} - tells the view whether or not it should be hidden
  #
  #            - singleChar {Boolean} - tells the view whether it should only listen for a single
  #                                      character or an entire string
  constructor: (@operation, opts={}) ->
    @editorView = @operation.editorView
    @vimState   = @operation.vimState

    @view = new VimCommandModeInputView(@, opts)
    @editorView.editor.commandModeInputView = @view
    # when the opStack is prematurely cleared we need to remove the view
    @editorView.on 'vim-mode:compose-failure', => @view.remove()

  # Public: Overriding this isn't usually necessary in subclasses, this pushes another operation
  #         to the `opStack` in `vim-stack.coffee` which causes the opStack to collapse and
  #         call execute/select on the parent operation
  #
  # view - the `VimCommandModeInputView` that called this method
  #
  # Returns nothing.
  confirm: (view) ->
    @vimState.pushOperations(new Input(@view.value))

  # Public: Overriding this isn't usually necessary in subclasses, this pushes an empty operation
  #         to the `opStack` in `vim-stack.coffee` which causes the opStack to collapse and
  #         call execute/select on the parent operation
  #
  # view - the `VimCommandModeInputView` that called this method
  #
  # Returns nothing.
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
