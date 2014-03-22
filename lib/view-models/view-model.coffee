VimCommandModeInputView = require './vim-command-mode-input-view'

module.exports =
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
  # opts - the options to be passed to `VimCommandModeInputView`
  #
  constructor: (@operator, opts={}) ->
    @editorView = @operator.editorView
    @vimState   = @operator.vimState ? @operator.state # so motions seem to have .state defined
                                                       # and operators have .vimState
                                                       # can we change this to be uniform across
                                                       # all types of operators?

    @view = new VimCommandModeInputView(@, opts)
    @editorView.editor.commandModeInputView = @view
    @editorView.on 'vim-mode:compose-failure', => @view.remove()

  # Public: Override this in subclasses for custom behavior when the `VimCommandModeInputView`
  #         has called `confirm`, optionally call super to get the default behavior of setting
  #         `@value` and triggering `@completionCommand`, if set
  #
  # view - the `VimCommandModeInputView` that called this method
  #
  confirm: (view) ->
    @vimState.pushOperations(new Input(@view.value))

  cancel: (view) ->
    @vimState.pushOperations(new Input())

class Input
  constructor: (@characters) ->
  isComplete: -> true
  isRecordable: -> true
