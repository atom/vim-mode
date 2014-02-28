_ = require 'underscore-plus'
{Point, Range} = require 'atom'

class Motion
  constructor: (@editor) ->
  isComplete: -> true
  isRecordable: -> false

class CurrentSelection extends Motion
  execute: (count=1) ->
    _.times(count, -> true)

  select: (count=1) ->
    _.times(count, -> true)

class SelectLeft extends Motion
  execute: (count=1) ->
    @select(count)

  select: (count=1) ->
    _.times count, =>
      @editor.selectLeft()
      true

class SelectRight extends Motion
  execute: (count=1) ->
    @select(count)

  select: (count=1) ->
    _.times count, =>
      @editor.selectRight()
      true

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

  select: (count=1) ->
    _.times count, =>
      @editor.selectUp()
      true

class MoveDown extends Motion
  execute: (count=1) ->
    _.times count, =>
      {row, column} = @editor.getCursorScreenPosition()
      @editor.moveCursorDown() if row < (@editor.getBuffer().getLineCount() - 1)

  select: (count=1) ->
    _.times count, =>
      @editor.selectDown()
      true

class MoveToPreviousWord extends Motion
  execute: (count=1) ->
    _.times count, =>
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

  # Private: Finds the end of the current word and stops on the last character
  #
  # exclusive - If true will stop on the last character of the word rather than
  #             the next character after the word.
  #
  # The reason this is implemented here is that Atom always stops on the
  # character after the word which is only sometimes what vim means.
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
    scanRange = [start, @editor.getEofBufferPosition()]

    {row, column} = @editor.getEofBufferPosition()
    position = new Point(row, column - 1)

    @editor.scanInBufferRange /^\n*$/g, scanRange, ({range, stop}) =>
      if !range.start.isEqual(start)
        position = range.start
        stop()

    @editor.screenPositionForBufferPosition(position)

class MoveToPreviousParagraph extends Motion
  execute: (count=1) ->
    _.times count, =>
      @editor.setCursorScreenPosition(@previousPosition())

  select: (count=1) ->
    _.times count, =>
      @editor.selectToScreenPosition(@previousPosition())
      true

  # Private: Finds the beginning of the previous paragraph
  #
  # If no paragraph is found, the beginning of the buffer is returned.
  previousPosition: ->
    start = @editor.getCursorBufferPosition()
    {row, column} = start
    scanRange = [[row-1, column], [0,0]]
    position = new Point(0, 0)
    @editor.backwardsScanInBufferRange /^\n*$/g, scanRange, ({range, stop}) =>
      if !range.start.isEqual(new Point(0,0))
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

  # Options
  #  requireEOL - if true, ensure an end of line character is always selected
  select: (count=1, {requireEOL}={}) ->
    {row, column} = @editor.getCursorBufferPosition()
    @editor.setSelectedBufferRange(@selectRows(row, row + (count - 1), requireEOL: requireEOL))

    _.times count, ->
      true

   # TODO: This is extracted from TextBuffer#deleteRows. Unfortunately
   # there isn't a way to call this functionality without actually
   # deleting at the same time. This should be extracted out within atom
   # and the removed here.
   selectRows: (start, end, {requireEOL}={}) =>
     startPoint = null
     endPoint = null
     buffer = @editor.getBuffer()
     if end == buffer.getLastRow()
       if start > 0 and requireEOL
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

module.exports = { Motion, CurrentSelection, SelectLeft, SelectRight, MoveLeft,
  MoveRight, MoveUp, MoveDown, MoveToPreviousWord, MoveToNextWord,
  MoveToEndOfWord, MoveToNextParagraph, MoveToPreviousParagraph, MoveToLine, MoveToBeginningOfLine,
  MoveToFirstCharacterOfLine, MoveToLastCharacterOfLine, MoveToStartOfFile }
