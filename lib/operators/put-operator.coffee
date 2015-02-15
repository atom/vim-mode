_ = require 'underscore-plus'
{Operator} = require './general-operators'
settings = require '../settings'

module.exports =
#
# It pastes everything contained within the specifed register
#
class Put extends Operator
  register: null

  constructor: (@editor, @vimState, {@location, @selectOptions}={}) ->
    @location ?= 'after'
    @complete = true
    @register = settings.defaultRegister()

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
            @editor.moveToEndOfLine()

            originalPosition = @editor.getCursorScreenPosition()
            originalPosition.row += 1
          else
            @editor.moveDown()
        else
          unless @onLastColumn()
            @editor.moveRight()

      if type == 'linewise' and !originalPosition?
        @editor.moveToBeginningOfLine()
        originalPosition = @editor.getCursorScreenPosition()

    @editor.insertText(textToInsert)

    if originalPosition?
      @editor.setCursorScreenPosition(originalPosition)
      @editor.moveToFirstCharacterOfLine()

    @vimState.activateCommandMode()
    if type != 'linewise'
      @editor.moveLeft()

  # Private: Helper to determine if the editor is currently on the last row.
  #
  # Returns true on the last row and false otherwise.
  onLastRow: ->
    {row, column} = @editor.getCursorBufferPosition()
    row == @editor.getBuffer().getLastRow()

  onLastColumn: ->
    @editor.getLastCursor().isAtEndOfLine()
