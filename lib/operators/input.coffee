{Operator} = require './general-operators'

# The operation for text entered in input mode. This operator is not
# used as the user types, but is created when the user leaves insert mode,
# and is available for repeating with the . operator (Replace)
#
# Currently, limitations with Transaction (from the text-buffer package)
# prevent us from doing anything reasonable with text input if it is
# anything but straight-up typed characters. No backspacing. It won't match
# vim when using the substitution command. You'll regret using this code.
# Never use this code.
#
class Input extends Operator
  constructor: (@editor, @vimState, @transaction) ->
    @typedText = @buildInsertText()

  buildInsertText: ->
    return undefined unless @isJustTyping()
    typedCharacters = (patch.newText for patch in @transaction.patches)
    typedCharacters.join("")

  # Determines if the transaction consists of just a set of typing without
  # deletions, which we can safely recreate.
  isJustTyping: ->
    return undefined unless @transaction
    typedSingleChars = (patch.oldText == "" && patch.newText != "" for patch in @transaction.patches)
    _.every(typedSingleChars)

  execute: ->
    return undefined unless @typedText
    @undoTransaction =>
      @editor.getBuffer().insert(@editor.getCursorBufferPosition(), @typedText, true)

    @undoTransaction =>
      start = editor.getCursorBufferPosition()
      _.times count, =>
        point = editor.getCursorBufferPosition()
        editor.setTextInBufferRange(Range.fromPointWithDelta(point, 0, 1), @viewModel.char)
        editor.moveCursorRight()
      editor.setCursorBufferPosition(start)
