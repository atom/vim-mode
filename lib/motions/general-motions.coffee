_ = require 'underscore-plus'
{Point, Range} = require 'atom'

WholeWordRegex = /\S+/
WholeWordOrEmptyLineRegex = /^\s*$|\S+/

class MotionError
  constructor: (@message) ->
    @name = 'Motion Error'

class Motion
  operatesInclusively: true
  operatesLinewise: false

  constructor: (@editor, @vimState) ->

  select: (count, options) ->
    value = for selection in @editor.getSelections()
      if @isLinewise()
        @moveSelectionLinewise(selection, count, options)
      else if @isInclusive()
        @moveSelectionInclusively(selection, count, options)
      else
        @moveSelection(selection, count, options)
      not selection.isEmpty()

    @editor.mergeCursors()
    @editor.mergeIntersectingSelections()
    value

  execute: (count) ->
    for cursor in @editor.getCursors()
      @moveCursor(cursor, count)
    @editor.mergeCursors()

  moveSelectionLinewise: (selection, count, options) ->
    selection.modifySelection =>
      [oldStartRow, oldEndRow] = selection.getBufferRowRange()

      wasEmpty = selection.isEmpty()
      wasReversed = selection.isReversed()
      unless wasEmpty or wasReversed
        selection.cursor.moveLeft()

      @moveCursor(selection.cursor, count, options)

      isEmpty = selection.isEmpty()
      isReversed = selection.isReversed()
      unless isEmpty or isReversed
        selection.cursor.moveRight()

      [newStartRow, newEndRow] = selection.getBufferRowRange()

      if isReversed and not wasReversed
        newEndRow = Math.max(newEndRow, oldStartRow)
      if wasReversed and not isReversed
        newStartRow = Math.min(newStartRow, oldEndRow)

      selection.setBufferRange([[newStartRow, 0], [newEndRow + 1, 0]])

  moveSelectionInclusively: (selection, count, options) ->
    selection.modifySelection =>
      range = selection.getBufferRange()
      [oldStart, oldEnd] = [range.start, range.end]

      wasEmpty = selection.isEmpty()
      wasReversed = selection.isReversed()
      unless wasEmpty or wasReversed
        selection.cursor.moveLeft()

      @moveCursor(selection.cursor, count, options)

      isEmpty = selection.isEmpty()
      isReversed = selection.isReversed()
      unless isEmpty or isReversed
        selection.cursor.moveRight()

      range = selection.getBufferRange()
      [newStart, newEnd] = [range.start, range.end]

      if (isReversed or isEmpty) and not (wasReversed or wasEmpty)
        selection.setBufferRange([newStart, [newEnd.row, oldStart.column + 1]])
      if wasReversed and not isReversed
        selection.setBufferRange([[newStart.row, oldEnd.column - 1], newEnd])

  moveSelection: (selection, count, options) ->
    selection.modifySelection => @moveCursor(selection.cursor, count, options)

  ensureCursorIsWithinLine: (cursor) ->
    return if @vimState.mode is 'visual' or not cursor.selection.isEmpty()
    {goalColumn} = cursor
    {row, column} = cursor.getBufferPosition()
    lastColumn = cursor.getCurrentLineBufferRange().end.column
    if column >= lastColumn - 1
      cursor.setBufferPosition([row, Math.max(lastColumn - 1, 0)])
    cursor.goalColumn ?= goalColumn

  isComplete: -> true

  isRecordable: -> false

  isLinewise: ->
    if @vimState?.mode is 'visual'
      @vimState?.submode is 'linewise'
    else
      @operatesLinewise

  isInclusive: ->
    @vimState.mode is 'visual' or @operatesInclusively

class CurrentSelection extends Motion
  constructor: (@editor, @vimState) ->
    super(@editor, @vimState)
    @selection = @editor.getSelectedBufferRanges()

  execute: (count=1) ->
    _.times(count, -> true)

  select: (count=1) ->
    @editor.setSelectedBufferRanges(@selection)
    _.times(count, -> true)

# Public: Generic class for motions that require extra input
class MotionWithInput extends Motion
  constructor: (@editor, @vimState) ->
    super(@editor, @vimState)
    @complete = false

  isComplete: -> @complete

  canComposeWith: (operation) -> return operation.characters?

  compose: (input) ->
    if not input.characters
      throw new MotionError('Must compose with an Input')
    @input = input
    @complete = true

class MoveLeft extends Motion
  operatesInclusively: false

  moveCursor: (cursor, count=1) ->
    _.times count, ->
      unless cursor.isAtBeginningOfLine()
        cursor.moveLeft()

class MoveRight extends Motion
  operatesInclusively: false

  moveCursor: (cursor, count=1) ->
    _.times count, =>
      cursor.moveRight() unless cursor.isAtEndOfLine()
      @ensureCursorIsWithinLine(cursor)

class MoveUp extends Motion
  operatesLinewise: true

  moveCursor: (cursor, count=1) ->
    _.times count, =>
      unless cursor.getBufferRow() is 0
        cursor.moveUp()
        @ensureCursorIsWithinLine(cursor)

class MoveDown extends Motion
  operatesLinewise: true

  moveCursor: (cursor, count=1) ->
    _.times count, =>
      unless cursor.getBufferRow() is @editor.getEofBufferPosition().row
        cursor.moveDown()
        @ensureCursorIsWithinLine(cursor)

class MoveToPreviousWord extends Motion
  operatesInclusively: false

  moveCursor: (cursor, count=1) ->
    _.times count, ->
      cursor.moveToBeginningOfWord()

class MoveToPreviousWholeWord extends Motion
  operatesInclusively: false

  moveCursor: (cursor, count=1) ->
    _.times count, =>
      cursor.moveToBeginningOfWord()
      while not @isWholeWord(cursor) and not @isBeginningOfFile(cursor)
        cursor.moveToBeginningOfWord()

  isWholeWord: (cursor) ->
    char = cursor.getCurrentWordPrefix().slice(-1)
    char is ' ' or char is '\n'

  isBeginningOfFile: (cursor) ->
    cur = cursor.getBufferPosition()
    not cur.row and not cur.column

class MoveToNextWord extends Motion
  wordRegex: null
  operatesInclusively: false

  moveCursor: (cursor, count=1, options) ->
    _.times count, =>
      current = cursor.getBufferPosition()

      next = if options?.excludeWhitespace
        cursor.getEndOfCurrentWordBufferPosition(wordRegex: @wordRegex)
      else
        cursor.getBeginningOfNextWordBufferPosition(wordRegex: @wordRegex)

      return if @isEndOfFile(cursor)

      if cursor.isAtEndOfLine()
        cursor.moveDown()
        cursor.moveToBeginningOfLine()
        cursor.skipLeadingWhitespace()
      else if current.row is next.row and current.column is next.column
        cursor.moveToEndOfWord()
      else
        cursor.setBufferPosition(next)

  isEndOfFile: (cursor) ->
    cur = cursor.getBufferPosition()
    eof = @editor.getEofBufferPosition()
    cur.row is eof.row and cur.column is eof.column

class MoveToNextWholeWord extends MoveToNextWord
  wordRegex: WholeWordOrEmptyLineRegex

class MoveToEndOfWord extends Motion
  wordRegex: null

  moveCursor: (cursor, count=1) ->
    _.times count, =>
      current = cursor.getBufferPosition()

      next = cursor.getEndOfCurrentWordBufferPosition(wordRegex: @wordRegex)
      next.column-- if next.column > 0

      if next.isEqual(current)
        cursor.moveRight()
        if cursor.isAtEndOfLine()
          cursor.moveDown()
          cursor.moveToBeginningOfLine()

        next = cursor.getEndOfCurrentWordBufferPosition(wordRegex: @wordRegex)
        next.column-- if next.column > 0

      cursor.setBufferPosition(next)

class MoveToEndOfWholeWord extends MoveToEndOfWord
  wordRegex: WholeWordRegex

class MoveToNextParagraph extends Motion
  operatesInclusively: false

  moveCursor: (cursor, count=1) ->
    _.times count, =>
      cursor.moveToBeginningOfNextParagraph()

class MoveToPreviousParagraph extends Motion
  moveCursor: (cursor, count=1) ->
    _.times count, =>
      cursor.moveToBeginningOfPreviousParagraph()

class MoveToLine extends Motion
  operatesLinewise: true

  getDestinationRow: (count) ->
    if count? then count - 1 else (@editor.getLineCount() - 1)

class MoveToAbsoluteLine extends MoveToLine
  moveCursor: (cursor, count) ->
    cursor.setBufferPosition([@getDestinationRow(count), Infinity])
    cursor.moveToFirstCharacterOfLine()
    cursor.moveToEndOfLine() if cursor.getBufferColumn() is 0

class MoveToRelativeLine extends MoveToLine
  operatesLinewise: true

  moveCursor: (cursor, count=1) ->
    {row, column} = cursor.getBufferPosition()
    cursor.setBufferPosition([row + (count - 1), 0])

class MoveToScreenLine extends MoveToLine
  constructor: (@editor, @vimState, @scrolloff) ->
    @scrolloff = 2 # atom default
    super(@editor, @vimState)

  moveCursor: (cursor, count=1) ->
    {row, column} = cursor.getBufferPosition()
    cursor.setScreenPosition([@getDestinationRow(count), 0])

class MoveToBeginningOfLine extends Motion
  operatesInclusively: false

  moveCursor: (cursor, count=1) ->
    _.times count, ->
      cursor.moveToBeginningOfLine()

class MoveToFirstCharacterOfLine extends Motion
  operatesInclusively: false

  moveCursor: (cursor, count=1) ->
    _.times count, ->
      cursor.moveToBeginningOfLine()
      cursor.moveToFirstCharacterOfLine()

class MoveToLastCharacterOfLine extends Motion
  operatesInclusively: false

  moveCursor: (cursor, count=1) ->
    _.times count, =>
      cursor.moveToEndOfLine()
      cursor.goalColumn = Infinity
      @ensureCursorIsWithinLine(cursor)

class MoveToFirstCharacterOfLineUp extends Motion
  operatesLinewise: true
  operatesInclusively: true

  moveCursor: (cursor, count=1) ->
    _.times count, ->
      cursor.moveUp()
    cursor.moveToBeginningOfLine()
    cursor.moveToFirstCharacterOfLine()

class MoveToFirstCharacterOfLineDown extends Motion
  operatesLinewise: true

  moveCursor: (cursor, count=1) ->
    _.times count, ->
      cursor.moveDown()
    cursor.moveToBeginningOfLine()
    cursor.moveToFirstCharacterOfLine()

class MoveToStartOfFile extends MoveToLine
  moveCursor: (cursor, count=1) ->
    {row, column} = @editor.getCursorBufferPosition()
    cursor.setBufferPosition([@getDestinationRow(count), 0])
    unless @isLinewise()
      cursor.moveToFirstCharacterOfLine()

class MoveToTopOfScreen extends MoveToScreenLine
  getDestinationRow: (count=0) ->
    firstScreenRow = @editor.getFirstVisibleScreenRow()
    if firstScreenRow > 0
      offset = Math.max(count - 1, @scrolloff)
    else
      offset = if count > 0 then count - 1 else count
    firstScreenRow + offset

class MoveToBottomOfScreen extends MoveToScreenLine
  getDestinationRow: (count=0) ->
    lastScreenRow = @editor.getLastVisibleScreenRow()
    lastRow = @editor.getBuffer().getLastRow()
    if lastScreenRow != lastRow
      offset = Math.max(count - 1, @scrolloff)
    else
      offset = if count > 0 then count - 1 else count
    lastScreenRow - offset

class MoveToMiddleOfScreen extends MoveToScreenLine
  getDestinationRow: (count) ->
    firstScreenRow = @editor.getFirstVisibleScreenRow()
    lastScreenRow = @editor.getLastVisibleScreenRow()
    height = lastScreenRow - firstScreenRow
    Math.floor(firstScreenRow + (height / 2))

module.exports = {
  Motion, MotionWithInput, CurrentSelection, MoveLeft, MoveRight, MoveUp, MoveDown,
  MoveToPreviousWord, MoveToPreviousWholeWord, MoveToNextWord, MoveToNextWholeWord,
  MoveToEndOfWord, MoveToNextParagraph, MoveToPreviousParagraph, MoveToAbsoluteLine, MoveToRelativeLine, MoveToBeginningOfLine,
  MoveToFirstCharacterOfLineUp, MoveToFirstCharacterOfLineDown,
  MoveToFirstCharacterOfLine, MoveToLastCharacterOfLine, MoveToStartOfFile, MoveToTopOfScreen,
  MoveToBottomOfScreen, MoveToMiddleOfScreen, MoveToEndOfWholeWord, MotionError
}
