_ = require 'underscore'

Point = require 'point'
Range = require 'range'

class Motion
  constructor: (@editor) ->
  isComplete: -> true

class MoveLeft extends Motion
  execute: (count=1) ->
    _.map [1..count], =>
      {row, column} = @editor.getCursorScreenPosition()
      @editor.moveCursorLeft() if column > 0

  select: (count=1) ->
    _.map [1..count], =>
      {row, column} = @editor.getCursorScreenPosition()

      if column > 0
        @editor.selectLeft()
        true
      else
        false

class MoveRight extends Motion
  execute: (count=1) ->
    _.map [1..count], =>
      {row, column} = @editor.getCursorScreenPosition()
      lastCharIndex = @editor.getBuffer().lineForRow(row).length - 1
      unless column >= lastCharIndex
        @editor.moveCursorRight()

class MoveUp extends Motion
  execute: (count=1) ->
    _.map [1..count], =>
      {row, column} = @editor.getCursorScreenPosition()
      @editor.moveCursorUp() if row > 0

class MoveDown extends Motion
  execute: (count=1) ->
    _.map [1..count], =>
      {row, column} = @editor.getCursorScreenPosition()
      @editor.moveCursorDown() if row < (@editor.getBuffer().getLineCount() - 1)

class MoveToPreviousWord extends Motion
  execute: (count=1) ->
    _.map [1..count], =>
      @editor.moveCursorToBeginningOfWord()

  select: (count=1) ->
    _.map [1..count], =>
      @editor.selectToBeginningOfWord()
      true

class MoveToNextWord extends Motion
  execute: (count=1) ->
    _.map [1..count], =>
      @editor.moveCursorToBeginningOfNextWord()

  select: (count=1) ->
    _.map [1..count], =>
      @editor.selectToBeginningOfNextWord()
      true

class MoveToNextParagraph extends Motion
  execute: (count=1) ->
    _.map [1..count], =>
      @editor.setCursorScreenPosition(@nextPosition())

  select: (count=1) ->
    _.map [1..count], =>
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

class MoveToLine extends Motion
  isLinewise: -> true

  execute: (count=1) ->
    # noop

  select: (count=1) ->
    {row, column} = @editor.getCursorBufferPosition()
    @editor.setSelectedBufferRange(@selectRows(row, row+(count-1)))

    _.map [1..count], (i) =>
      true

   # TODO: This is extracted from TextBuffer#deleteRows. Unfortunately
   # there isn't a way to call this functionality without actually
   # deleting at the same time. This should be extracted out within atom
   # and the removed here.
   selectRows: (start, end) =>
     startPoint = null
     endPoint = null
     buffer = @editor.getBuffer()
     if end == buffer.getLastRow()
       if start > 0
         startPoint = [start - 1, buffer.lineLengthForRow(start - 1)]
       else
         startPoint = [start, 0]
       endPoint = [end, buffer.lineLengthForRow(end)]
     else
       startPoint = [start, 0]
       endPoint = [end + 1, 0]

      new Range(startPoint, endPoint)

class MoveToFirstCharacterOfLine extends Motion
  execute: (count=1) ->
    _.map [1..count], =>
      @editor.moveCursorToFirstCharacterOfLine()

  select: (count=1) ->
    _.map [1..count], =>
      @editor.selectToFirstCharacterOfLine()
      true

class MoveToLastCharacterOfLine extends Motion
  execute: (count=1) ->
    _.map [1..count], =>
      @editor.moveCursorToEndOfLine()

  select: (count=1) ->
    _.map [1..count], =>
      @editor.selectToEndOfLine()
      true

module.exports = { Motion, MoveLeft, MoveRight, MoveUp, MoveDown, MoveToNextWord, MoveToPreviousWord, MoveToNextParagraph, MoveToFirstCharacterOfLine, MoveToLastCharacterOfLine, MoveToLine }
