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

  select: (count=1) ->
    _.map [1..count], =>
      {start, end} = @editor.getSelectedBufferRange()
      rowLength = @editor.getCursor().getCurrentBufferLine().length

      if end.column < rowLength
        @editor.selectRight()
        true
      else
        false

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
    cursor = @editor.getCursor()

    _.map [1..count], =>
      {row, column} = cursor.getBufferPosition()
      word = cursor.getBeginningOfNextWordBufferPosition()

      if row != word.row
        @editor.selectToEndOfWord()
      else
        @editor.selectToBeginningOfNextWord()

      true

class MoveToEndOfWord extends Motion
  execute: (count=1) ->
    cursor = @editor.getCursor()
    _.map [1..count], =>
      cursor.setBufferPosition(@nextBufferPosition(exclusive: true))

  select: (count=1) ->
    cursor = @editor.getCursor()

    _.map [1..count], =>
      bufferPosition = @nextBufferPosition()
      screenPosition = @editor.screenPositionForBufferPosition(bufferPosition)
      @editor.selectToScreenPosition(screenPosition)
      true

  nextBufferPosition: ({exclusive}={})->
    cursor = @editor.getCursor()
    current = cursor.getBufferPosition()
    next = cursor.getEndOfCurrentWordBufferPosition()
    next.column -= 1 if exclusive

    if exclusive and current.row == next.row and current.column == next.column
      cursor.moveRight()
      next = cursor.getEndOfCurrentWordBufferPosition()
      next.column -= 1

    next

class MoveToNextParagraph extends Motion
  execute: (count=1) ->
    _.map [1..count], =>
      @editor.setCursorScreenPosition(@nextPosition())

  select: (count=1) ->
    _.map [1..count], =>
      @editor.selectToScreenPosition(@nextPosition())
      true

  # Private: Finds the beginning of the next paragraph
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

class MoveToBeginningOfLine extends Motion
  execute: (count=1) ->
    _.map [1..count], =>
      @editor.moveCursorToBeginningOfLine()

  select: (count=1) ->
    _.map [1..count], =>
      @editor.selectToBeginningOfLine()
      true

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

class MoveToStartOfFile extends Motion
  execute: (count=1) ->
    _.map [1..count], =>
      @editor.setCursorScreenPosition([0,0])
      @editor.getCursor().skipLeadingWhitespace()

  select: (count=1) ->
    _.map [1..count], =>
      @editor.selectToScreenPosition([0,0])

class MoveToEndOfFile extends Motion
  execute: (count=1) ->
    _.map [1..count], =>
      @editor.setCursorScreenPosition(@endOfFile())

  select: (count=1) ->
    _.map [1..count], =>
      @editor.selectToScreenPosition(@endOfFile())

  endOfFile: ->
    @editor.screenPositionForBufferPosition @editor.getEofPosition()

module.exports = { Motion, MoveLeft, MoveRight, MoveUp, MoveDown, MoveToNextWord,
  MoveToPreviousWord, MoveToNextParagraph, MoveToFirstCharacterOfLine,
  MoveToLastCharacterOfLine, MoveToLine, MoveToBeginningOfLine, MoveToStartOfFile,
  MoveToEndOfFile, MoveToEndOfWord }
