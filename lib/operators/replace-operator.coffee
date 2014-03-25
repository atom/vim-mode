_ = require 'underscore-plus'
{OperatorWithInput} = require './general-operators'
{ViewModel} = require '../view-models/view-model'
{Range} = require 'atom'

module.exports =
class Replace extends OperatorWithInput
  constructor: (@editorView, @vimState, {@selectOptions}={}) ->
    super(@editorView, @vimState)
    @viewModel = new ViewModel(@, class: 'replace', hidden: true, singleChar: true)

  execute: (count=1) ->
    pos = @editor.getCursorBufferPosition()
    currentRowLength = @editor.lineLengthForBufferRow(pos.row)

    # Do nothing on an empty line
    return unless currentRowLength > 0
    # Do nothing if asked to replace more characters than there are on a line
    return unless currentRowLength - pos.column >= count

    @undoTransaction =>
      start = @editor.getCursorBufferPosition()
      _.times count, =>
        point = @editor.getCursorBufferPosition()
        @editor.setTextInBufferRange(Range.fromPointWithDelta(point, 0, 1), @input.characters)
        @editor.moveCursorRight()
      @editor.setCursorBufferPosition(start)

    @vimState.activateCommandMode()
