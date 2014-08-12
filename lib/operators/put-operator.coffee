_ = require 'underscore-plus'
{Operator} = require './general-operators'

module.exports =
#
# It pastes everything contained within the specifed register
#
class Put extends Operator
  register: '"'

  constructor: (@editor, @vimState, {@location, @selectOptions}={}) ->
    @location ?= 'after'
    @complete = true

  # Public: Pastes the text in the given register.
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: (count=1) ->
    {text, type} = @vimState.getRegister(@register) || {}
    return unless text

    textToInsert = _.times(count, -> text).join('')

    selection = @editor.getSelectedBufferRange()
    if selection.isEmpty()
      # Clean up some corner cases on the last line of the file
      if type == 'linewise'
        textToInsert = textToInsert.replace(/\n$/, '')
        if @location == 'after' and @onLastRow()
          textToInsert = "\n#{textToInsert}"
        else
          textToInsert = "#{textToInsert}\n"

      if @location == 'after'
        if type == 'linewise'
          if @onLastRow()
            @editor.moveCursorToEndOfLine()

            originalPosition = @editor.getCursorScreenPosition()
            originalPosition.row += 1
          else
            @editor.moveCursorDown()
        else
          unless @onLastColumn()
            @editor.moveCursorRight()

      if type == 'linewise' and !originalPosition?
        @editor.moveCursorToBeginningOfLine()
        originalPosition = @editor.getCursorScreenPosition()

    @editor.insertText(textToInsert)

    if originalPosition?
      @editor.setCursorScreenPosition(originalPosition)
      @editor.moveCursorToFirstCharacterOfLine()

    @vimState.activateCommandMode()
    if type != 'linewise'
      @editor.moveCursorLeft()

  # Private: Helper to determine if the editor is currently on the last row.
  #
  # Returns true on the last row and false otherwise.
  onLastRow: ->
    {row, column} = @editor.getCursorBufferPosition()
    row == @editor.getBuffer().getLastRow()

  onLastColumn: ->
    @editor.getCursor().isAtEndOfLine()
