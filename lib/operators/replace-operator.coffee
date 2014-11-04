_ = require 'underscore-plus'
{OperatorWithInput} = require './general-operators'
{ViewModel} = require '../view-models/view-model'
{Range} = require 'atom'

module.exports =
class Replace extends OperatorWithInput
  constructor: (@editorView, @vimState, {@selectOptions}={}) ->
    super(@editorView, @vimState)
    @viewModel = new ViewModel(@, class: 'replace', hidden: true, singleChar: true, defaultText: '\n')

  execute: (count=1) ->
    pos = @editor.getCursorBufferPosition()
    currentRowLength = @editor.lineTextForBufferRow(pos.row).length

    # Do nothing on an empty line
    return unless currentRowLength > 0
    # Do nothing if asked to replace more characters than there are on a line
    return unless currentRowLength - pos.column >= count

    @undoTransaction =>
      start = @editor.getCursorBufferPosition()
      _.times count, =>
        point = @editor.getCursorBufferPosition()
        @editor.setTextInBufferRange(Range.fromPointWithDelta(point, 0, 1), @input.characters)
        @editor.moveRight()
      @editor.setCursorBufferPosition(start)

      # Special case: when replaced with a newline move to the start of
      # the next row.
      if @input.characters is "\n"
        _.times count, =>
          @editor.moveDown()
        @editor.moveToFirstCharacterOfLine()

    @vimState.activateCommandMode()
