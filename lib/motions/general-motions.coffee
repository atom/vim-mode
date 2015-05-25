_ = require 'underscore-plus'
{Point, Range} = require 'atom'
settings = require '../settings'

WholeWordRegex = /\S+/
WholeWordOrEmptyLineRegex = /^\s*$|\S+/
AllWhitespace = /^\s$/

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
      if wasReversed and not wasEmpty and not isReversed
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
    _.times count, =>
      cursor.moveLeft() if not cursor.isAtBeginningOfLine() or settings.wrapLeftRightMotion()
      @ensureCursorIsWithinLine(cursor)

class MoveRight extends Motion
  operatesInclusively: false

  moveCursor: (cursor, count=1) ->
    _.times count, =>
      wrapToNextLine = settings.wrapLeftRightMotion()

      # when the motion is combined with an operator, we will only wrap to the next line
      # if we are already at the end of the line (after the last character)
      wrapToNextLine = false if @vimState.mode is 'operator-pending' and not cursor.isAtEndOfLine()

      cursor.moveRight() unless cursor.isAtEndOfLine()
      cursor.moveRight() if wrapToNextLine and cursor.isAtEndOfLine()
      @ensureCursorIsWithinLine(cursor)

class MoveUp extends Motion
  operatesLinewise: true

  moveCursor: (cursor, count=1) ->
    _.times count, =>
      unless cursor.getScreenRow() is 0
        cursor.moveUp()
        @ensureCursorIsWithinLine(cursor)

class MoveDown extends Motion
  operatesLinewise: true

  moveCursor: (cursor, count=1) ->
    _.times count, =>
      unless cursor.getScreenRow() is @editor.getLastScreenRow()
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
    AllWhitespace.test(char)

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
    _.times count, ->
      cursor.moveToBeginningOfNextParagraph()

class MoveToPreviousParagraph extends Motion
  moveCursor: (cursor, count=1) ->
    _.times count, ->
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
  constructor: (@editorElement, @vimState, @scrolloff) ->
    @scrolloff = 2 # atom default
    super(@editorElement.getModel(), @vimState)

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

class MoveToFirstCharacterOfLineAndDown extends Motion
  operatesLinewise: true
  operatesInclusively: true

  moveCursor: (cursor, count=0) ->
    _.times count-1, ->
      cursor.moveDown()
    cursor.moveToBeginningOfLine()
    cursor.moveToFirstCharacterOfLine()

class MoveToLastCharacterOfLine extends Motion
  operatesInclusively: false

  moveCursor: (cursor, count=1) ->
    _.times count, =>
      cursor.moveToEndOfLine()
      cursor.goalColumn = Infinity
      @ensureCursorIsWithinLine(cursor)

class MoveToLastNonblankCharacterOfLineAndDown extends Motion
  operatesInclusively: true

  # moves cursor to the last non-whitespace character on the line
  # similar to skipLeadingWhitespace() in atom's cursor.coffee
  skipTrailingWhitespace: (cursor) ->
    position = cursor.getBufferPosition()
    scanRange = cursor.getCurrentLineBufferRange()
    startOfTrailingWhitespace = [scanRange.end.row, scanRange.end.column - 1]
    @editor.scanInBufferRange /[ \t]+$/, scanRange, ({range}) ->
      startOfTrailingWhitespace = range.start
      startOfTrailingWhitespace.column -= 1
    cursor.setBufferPosition(startOfTrailingWhitespace)

  moveCursor: (cursor, count=1) ->
    _.times count-1, ->
      cursor.moveDown()
    @skipTrailingWhitespace(cursor)

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
    firstScreenRow = @editorElement.getFirstVisibleScreenRow()
    if firstScreenRow > 0
      offset = Math.max(count - 1, @scrolloff)
    else
      offset = if count > 0 then count - 1 else count
    firstScreenRow + offset

class MoveToBottomOfScreen extends MoveToScreenLine
  getDestinationRow: (count=0) ->
    lastScreenRow = @editorElement.getLastVisibleScreenRow()
    lastRow = @editor.getBuffer().getLastRow()
    if lastScreenRow isnt lastRow
      offset = Math.max(count - 1, @scrolloff)
    else
      offset = if count > 0 then count - 1 else count
    lastScreenRow - offset

class MoveToMiddleOfScreen extends MoveToScreenLine
  getDestinationRow: (count) ->
    firstScreenRow = @editorElement.getFirstVisibleScreenRow()
    lastScreenRow = @editorElement.getLastVisibleScreenRow()
    height = lastScreenRow - firstScreenRow
    Math.floor(firstScreenRow + (height / 2))

class ScrollKeepingCursor extends MoveToLine
  previousFirstScreenRow: 0
  currentFirstScreenRow: 0

  constructor: (@editorElement, @vimState) ->
    super(@editorElement.getModel(), @vimState)

  select: (count, options) ->
    finalDestination = @scrollScreen(count)
    super(count, options)
    @editor.setScrollTop(finalDestination)

  execute: (count) ->
    finalDestination = @scrollScreen(count)
    super(count)
    @editor.setScrollTop(finalDestination)

  moveCursor: (cursor, count=1) ->
    cursor.setScreenPosition([@getDestinationRow(count), 0])

  getDestinationRow: (count) ->
    {row, column} = @editor.getCursorScreenPosition()
    @currentFirstScreenRow - @previousFirstScreenRow + row

  scrollScreen: (count = 1) ->
    @previousFirstScreenRow = @editorElement.getFirstVisibleScreenRow()
    destination = @scrollDestination(count)
    @editor.setScrollTop(destination)
    @currentFirstScreenRow = @editorElement.getFirstVisibleScreenRow()
    destination

class ScrollHalfUpKeepCursor extends ScrollKeepingCursor
  scrollDestination: (count) ->
    half = (Math.floor(@editor.getRowsPerPage() / 2) * @editor.getLineHeightInPixels())
    @editor.getScrollTop() - count * half

class ScrollFullUpKeepCursor extends ScrollKeepingCursor
  scrollDestination: (count) ->
    @editor.getScrollTop() - (count * @editor.getHeight())

class ScrollHalfDownKeepCursor extends ScrollKeepingCursor
  scrollDestination: (count) ->
    half = (Math.floor(@editor.getRowsPerPage() / 2) * @editor.getLineHeightInPixels())
    @editor.getScrollTop() + count * half

class ScrollFullDownKeepCursor extends ScrollKeepingCursor
  scrollDestination: (count) ->
    @editor.getScrollTop() + (count * @editor.getHeight())

module.exports = {
  Motion, MotionWithInput, CurrentSelection, MoveLeft, MoveRight, MoveUp, MoveDown,
  MoveToPreviousWord, MoveToPreviousWholeWord, MoveToNextWord, MoveToNextWholeWord,
  MoveToEndOfWord, MoveToNextParagraph, MoveToPreviousParagraph, MoveToAbsoluteLine, MoveToRelativeLine, MoveToBeginningOfLine,
  MoveToFirstCharacterOfLineUp, MoveToFirstCharacterOfLineDown,
  MoveToFirstCharacterOfLine, MoveToFirstCharacterOfLineAndDown, MoveToLastCharacterOfLine,
  MoveToLastNonblankCharacterOfLineAndDown, MoveToStartOfFile,
  MoveToTopOfScreen, MoveToBottomOfScreen, MoveToMiddleOfScreen, MoveToEndOfWholeWord, MotionError,
  ScrollHalfUpKeepCursor, ScrollFullUpKeepCursor,
  ScrollHalfDownKeepCursor, ScrollFullDownKeepCursor
}
