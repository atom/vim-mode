_ = require 'underscore-plus'
{OperatorWithInput} = require './general-operators'
{ViewModel} = require '../view-models/view-model'
{Range} = require 'atom'

module.exports =
class Replace extends OperatorWithInput
  constructor: (@editor, @vimState) ->
    super(@editor, @vimState)
    @viewModel = new ViewModel(this, class: 'replace', hidden: true, singleChar: true, defaultText: '\n')

  execute: (count=1) ->
    if @input.characters is ""
      # replace canceled

      if @vimState.mode is "visual"
        @vimState.resetVisualMode()
      else
        @vimState.activateNormalMode()

      return

    # todo add specs with bracket matcher, for both editor.replaceSelectedText and editor.setTextInBufferRange
    @editor.transact =>
      if @motion?
        if _.contains(@motion.select(), true)
          @editor.replaceSelectedText null, (text) =>
            text.replace(/./g, @input.characters)
          for selection in @editor.getSelections()
            point = selection.getBufferRange().start
            selection.setBufferRange(Range.fromPointWithDelta(point, 0, 0))
      else
        for cursor in @editor.getCursors()
          pos = cursor.getBufferPosition()
          currentRowLength = @editor.lineTextForBufferRow(pos.row).length
          continue unless currentRowLength - pos.column >= count

          _.times count, =>
            point = cursor.getBufferPosition()
            @editor.setTextInBufferRange(Range.fromPointWithDelta(point, 0, 1), @input.characters)
            cursor.moveRight()
          cursor.setBufferPosition(pos)

        # Special case: when replaced with a newline move to the start of the
        # next row.
        if @input.characters is "\n"
          _.times count, =>
            @editor.moveDown()
          @editor.moveToFirstCharacterOfLine()

    @vimState.activateNormalMode()
