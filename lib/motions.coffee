_ = require 'underscore'

Point = require 'point'
Range = require 'range'

class Motion
  constructor: (@editor) ->
  isComplete: -> true

class MoveLeft extends Motion
  execute: (count=1) ->
    _.times count, =>
      {row, column} = @editor.getCursorScreenPosition()
      @editor.moveCursorLeft() if column > 0

  select: (count=1) ->
    _.times count, =>
      {row, column} = @editor.getCursorScreenPosition()

      if column > 0
        @editor.selectLeft()
        true
      else
        false

class MoveRight extends Motion
  execute: (count=1) ->
    _.times count, =>
      {row, column} = @editor.getCursorScreenPosition()
      lastCharIndex = @editor.getBuffer().lineForRow(row).length - 1
      unless column >= lastCharIndex
        @editor.moveCursorRight()

  select: (count=1) ->
    _.times count, =>
      {start, end} = @editor.getSelectedBufferRange()
      rowLength = @editor.getCursor().getCurrentBufferLine().length

      if end.column < rowLength
        @editor.selectRight()
        true
      else
        false

class MoveUp extends Motion
  execute: (count=1) ->
    _.times count, =>
      {row, column} = @editor.getCursorScreenPosition()
      @editor.moveCursorUp() if row > 0

class MoveDown extends Motion
  execute: (count=1) ->
    _.times count, =>
      {row, column} = @editor.getCursorScreenPosition()
      @editor.moveCursorDown() if row < (@editor.getBuffer().getLineCount() - 1)

class MoveToPreviousWord extends Motion
  execute: (count=1) ->
    _.time count, =>
      @editor.moveCursorToBeginningOfWord()

  select: (count=1) ->
    _.times count, =>
      @editor.selectToBeginningOfWord()
      true

class MoveToNextWord extends Motion
  execute: (count=1) ->
    _.times count, =>
      @editor.moveCursorToBeginningOfNextWord()

  # Options
  #  excludeWhitespace - if true, whitespace shouldn't be selected
  select: (count=1, {excludeWhitespace}={}) ->
    cursor = @editor.getCursor()

    _.times count, =>
      current = cursor.getBufferPosition()
      next = cursor.getBeginningOfNextWordBufferPosition()

      if current.row != next.row or excludeWhitespace
        @editor.selectToEndOfWord()
      else
        @editor.selectToBeginningOfNextWord()

      true

class MoveToEndOfWord extends Motion
  execute: (count=1) ->
    cursor = @editor.getCursor()
    _.times count, =>
      cursor.setBufferPosition(@nextBufferPosition(exclusive: true))

  select: (count=1) ->
    cursor = @editor.getCursor()

    _.times count, =>
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
    _.times count, =>
      @editor.setCursorScreenPosition(@nextPosition())

  select: (count=1) ->
    _.times count, =>
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

  execute: (count) ->
    if count?
      @editor.setCursorBufferPosition([count - 1, 0])
    else
      @editor.setCursorBufferPosition([@editor.getLineCount() - 1, 0])
    @editor.getCursor().skipLeadingWhitespace()

  select: (count=1) ->
    {row, column} = @editor.getCursorBufferPosition()
    @editor.setSelectedBufferRange(@selectRows(row, row+(count-1)))

    _.times count, ->
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
    _.times count, =>
      @editor.moveCursorToBeginningOfLine()

  select: (count=1) ->
    _.times count, =>
      @editor.selectToBeginningOfLine()
      true

class MoveToFirstCharacterOfLine extends Motion
  execute: (count=1) ->
    _.times count, =>
      @editor.moveCursorToFirstCharacterOfLine()

  select: (count=1) ->
    _.times count, =>
      @editor.selectToFirstCharacterOfLine()
      true

class MoveToLastCharacterOfLine extends Motion
  execute: (count=1) ->
    _.times count, =>
      @editor.moveCursorToEndOfLine()

  select: (count=1) ->
    _.times count, =>
      @editor.selectToEndOfLine()
      true

class MoveToStartOfFile extends MoveToLine
  execute: (count=1) ->
    super(count)

module.exports = { Motion, MoveLeft, MoveRight, MoveUp, MoveDown,
  MoveToPreviousWord, MoveToNextWord, MoveToEndOfWord, MoveToNextParagraph,
  MoveToLine, MoveToBeginningOfLine, MoveToFirstCharacterOfLine,
  MoveToLastCharacterOfLine, MoveToStartOfFile }
