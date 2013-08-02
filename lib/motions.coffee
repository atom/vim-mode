Point = require 'point'

class Motion
  constructor: (@editor) ->
  isComplete: -> true

class MoveLeft extends Motion
  execute: ->
    {row, column} = @editor.getCursorScreenPosition()
    @editor.moveCursorLeft() if column > 0

  select: ->
    {row, column} = @editor.getCursorScreenPosition()

    if column > 0
      @editor.selectLeft()
      true
    else
      false

class MoveRight extends Motion
  execute: ->
    {row, column} = @editor.getCursorScreenPosition()
    lastCharIndex = @editor.getBuffer().lineForRow(row).length - 1
    unless column >= lastCharIndex
      @editor.moveCursorRight()

class MoveUp extends Motion
  execute: ->
    {row, column} = @editor.getCursorScreenPosition()
    @editor.moveCursorUp() if row > 0

class MoveDown extends Motion
  execute: ->
    {row, column} = @editor.getCursorScreenPosition()
    @editor.moveCursorDown() if row < (@editor.getBuffer().getLineCount() - 1)

class MoveToPreviousWord extends Motion
  execute: ->
    @editor.moveCursorToBeginningOfWord()

  select: ->
    @editor.selectToBeginningOfWord()
    true

class MoveToNextWord extends Motion
  execute: ->
    @editor.moveCursorToBeginningOfNextWord()

  select: ->
    @editor.selectToBeginningOfNextWord()
    true

class MoveToNextParagraph extends Motion
  execute: ->
    @editor.setCursorScreenPosition(@nextPosition())

  select: ->
    @editor.selectToScreenPosition(@nextPosition())
    true

  # Finds the beginning of the next paragraph
  #
  # If no paragraph is found, the end of the buffer is returned.
  nextPosition: ->
    start = @editor.getCursorBufferPosition()
    scanRange = [start, @editor.getEofPosition()]

    {row, column} = @editor.getEofPosition()
    position = new Point(row, column - 1)

    @editor.scanInBufferRange /^$/g, scanRange, ({range, stop}) =>
      if !range.start.isEqual(start)
        position = range.start
        stop()

    @editor.screenPositionForBufferPosition(position)

class MoveToFirstCharacterOfLine extends Motion
  execute: ->
    @editor.moveCursorToFirstCharacterOfLine()

  select: ->
    @editor.selectToFirstCharacterOfLine()
    true

class MoveToLastCharacterOfLine extends Motion
  execute: ->
    @editor.moveCursorToEndOfLine()

  select: ->
    @editor.selectToEndOfLine()
    true

module.exports = { Motion, MoveLeft, MoveRight, MoveUp, MoveDown, MoveToNextWord, MoveToPreviousWord, MoveToNextParagraph, MoveToFirstCharacterOfLine, MoveToLastCharacterOfLine }
