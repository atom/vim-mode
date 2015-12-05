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
  operatesInclusively: false
  operatesLinewise: false

  constructor: (@editor, @vimState) ->

  select: (count, options) ->
    value = for selection in @editor.getSelections()
      if @isLinewise()
        @moveSelectionLinewise(selection, count, options)
      else if @vimState.mode is 'visual'
        @moveSelectionVisual(selection, count, options)
      else if @operatesInclusively
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

      selection.setBufferRange([[newStartRow, 0], [newEndRow + 1, 0]], autoscroll: false)

  moveSelectionInclusively: (selection, count, options) ->
    return @moveSelectionVisual(selection, count, options) unless selection.isEmpty()

    selection.modifySelection =>
      @moveCursor(selection.cursor, count, options)
      return if selection.isEmpty()

      if selection.isReversed()
        # for backward motion, add the original starting character of the motion
        {start, end} = selection.getBufferRange()
        selection.setBufferRange([start, [end.row, end.column + 1]])
      else
        # for forward motion, add the ending character of the motion
        selection.cursor.moveRight()

  moveSelectionVisual: (selection, count, options) ->
    selection.modifySelection =>
      range = selection.getBufferRange()
      [oldStart, oldEnd] = [range.start, range.end]

      # in visual mode, atom cursor is after the last selected character,
      # so here put cursor in the expected place for the following motion
      wasEmpty = selection.isEmpty()
      wasReversed = selection.isReversed()
      unless wasEmpty or wasReversed
        selection.cursor.moveLeft()

      @moveCursor(selection.cursor, count, options)

      # put cursor back after the last character so it is also selected
      isEmpty = selection.isEmpty()
      isReversed = selection.isReversed()
      unless isEmpty or isReversed
        selection.cursor.moveRight()

      range = selection.getBufferRange()
      [newStart, newEnd] = [range.start, range.end]

      # if we reversed or emptied a normal selection
      # we need to select again the last character deselected above the motion
      if (isReversed or isEmpty) and not (wasReversed or wasEmpty)
        selection.setBufferRange([newStart, [newEnd.row, oldStart.column + 1]])

      # if we re-reversed a reversed non-empty selection,
      # we need to keep the last character of the old selection selected
      if wasReversed and not wasEmpty and not isReversed
        selection.setBufferRange([[oldEnd.row, oldEnd.column - 1], newEnd])

      # keep a single-character selection non-reversed
      range = selection.getBufferRange()
      [newStart, newEnd] = [range.start, range.end]
      if selection.isReversed() and newStart.row is newEnd.row and newStart.column + 1 is newEnd.column
        selection.setBufferRange(range, reversed: false)

  moveSelection: (selection, count, options) ->
    selection.modifySelection => @moveCursor(selection.cursor, count, options)

  isComplete: -> true

  isRecordable: -> false

  isLinewise: ->
    if @vimState?.mode is 'visual'
      @vimState?.submode is 'linewise'
    else
      @operatesLinewise

class CurrentSelection extends Motion
  constructor: (@editor, @vimState) ->
    super(@editor, @vimState)
    @lastSelectionRange = @editor.getSelectedBufferRange()
    @wasLinewise = @isLinewise()

  execute: (count=1) ->
    _.times(count, -> true)

  select: (count=1) ->
    # in visual mode, the current selections are already there
    # if we're not in visual mode, we are repeating some operation and need to re-do the selections
    unless @vimState.mode is 'visual'
      if @wasLinewise
        @selectLines()
      else
        @selectCharacters()

    _.times(count, -> true)

  selectLines: ->
    lastSelectionExtent = @lastSelectionRange.getExtent()
    for selection in @editor.getSelections()
      cursor = selection.cursor.getBufferPosition()
      selection.setBufferRange [[cursor.row, 0], [cursor.row + lastSelectionExtent.row, 0]]
    return

  selectCharacters: ->
    lastSelectionExtent = @lastSelectionRange.getExtent()
    for selection in @editor.getSelections()
      {start} = selection.getBufferRange()
      newEnd = start.traverse(lastSelectionExtent)
      selection.setBufferRange([start, newEnd])
    return

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
  moveCursor: (cursor, count=1) ->
    _.times count, ->
      cursor.moveLeft() if not cursor.isAtBeginningOfLine() or settings.wrapLeftRightMotion()

class MoveRight extends Motion
  moveCursor: (cursor, count=1) ->
    _.times count, =>
      wrapToNextLine = settings.wrapLeftRightMotion()

      # when the motion is combined with an operator, we will only wrap to the next line
      # if we are already at the end of the line (after the last character)
      wrapToNextLine = false if @vimState.mode is 'operator-pending' and not cursor.isAtEndOfLine()

      cursor.moveRight() unless cursor.isAtEndOfLine()
      cursor.moveRight() if wrapToNextLine and cursor.isAtEndOfLine()

class MoveUp extends Motion
  operatesLinewise: true

  moveCursor: (cursor, count=1) ->
    _.times count, ->
      unless cursor.getScreenRow() is 0
        cursor.moveUp()

class MoveDown extends Motion
  operatesLinewise: true

  moveCursor: (cursor, count=1) ->
    _.times count, =>
      unless cursor.getScreenRow() is @editor.getLastScreenRow()
        cursor.moveDown()

class MoveToPreviousWord extends Motion
  moveCursor: (cursor, count=1) ->
    _.times count, ->
      cursor.moveToBeginningOfWord()

class MoveToPreviousWholeWord extends Motion
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
  operatesInclusively: true
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

class MoveToNextSentence extends Motion
  moveCursor: (cursor, count=1) ->
    _.times count, ->
      start = cursor.getBufferPosition().translate new Point(0, 1)
      eof = cursor.editor.getBuffer().getEndPosition()
      scanRange = [start, eof]

      cursor.editor.scanInBufferRange /(^$)|(([\.!?] )|^[A-Za-z0-9])/, scanRange, ({matchText, range, stop}) ->
        adjustment = new Point(0, 0)
        if matchText.match /[\.!?]/
          adjustment = new Point(0, 2)

        cursor.setBufferPosition range.start.translate(adjustment)
        stop()

class MoveToPreviousSentence extends Motion
  moveCursor: (cursor, count=1) ->
    _.times count, ->
      end = cursor.getBufferPosition().translate new Point(0, -1)
      bof = cursor.editor.getBuffer().getFirstPosition()
      scanRange = [bof, end]

      cursor.editor.backwardsScanInBufferRange /(^$)|(([\.!?] )|^[A-Za-z0-9])/, scanRange, ({matchText, range, stop}) ->
        adjustment = new Point(0, 0)
        if matchText.match /[\.!?]/
          adjustment = new Point(0, 2)

        cursor.setBufferPosition range.start.translate(adjustment)
        stop()

class MoveToNextParagraph extends Motion
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
  moveCursor: (cursor, count=1) ->
    _.times count, ->
      cursor.moveToBeginningOfLine()

class MoveToFirstCharacterOfLine extends Motion
  moveCursor: (cursor, count=1) ->
    _.times count, ->
      cursor.moveToBeginningOfLine()
      cursor.moveToFirstCharacterOfLine()

class MoveToFirstCharacterOfLineAndDown extends Motion
  operatesLinewise: true

  moveCursor: (cursor, count=1) ->
    _.times count-1, ->
      cursor.moveDown()
    cursor.moveToBeginningOfLine()
    cursor.moveToFirstCharacterOfLine()

class MoveToLastCharacterOfLine extends Motion
  moveCursor: (cursor, count=1) ->
    _.times count, ->
      cursor.moveToEndOfLine()
      cursor.goalColumn = Infinity

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
  getDestinationRow: ->
    firstScreenRow = @editorElement.getFirstVisibleScreenRow()
    lastScreenRow = @editorElement.getLastVisibleScreenRow()
    height = lastScreenRow - firstScreenRow
    Math.floor(firstScreenRow + (height / 2))

class ScrollKeepingCursor extends Motion
  operatesLinewise: true
  cursorRow: null

  constructor: (@editorElement, @vimState) ->
    super(@editorElement.getModel(), @vimState)

  select: (count, options) ->
    # TODO: remove this conditional once after Atom v1.1.0 is released.
    if @editor.setFirstVisibleScreenRow?
      newTopRow = @getNewFirstVisibleScreenRow(count)
      super(count, options)
      @editor.setFirstVisibleScreenRow(newTopRow)
    else
      scrollTop = @getNewScrollTop(count)
      super(count, options)
      @editorElement.setScrollTop(scrollTop)

  execute: (count) ->
    # TODO: remove this conditional once after Atom v1.1.0 is released.
    if @editor.setFirstVisibleScreenRow?
      newTopRow = @getNewFirstVisibleScreenRow(count)
      super(count)
      @editor.setFirstVisibleScreenRow(newTopRow)
    else
      scrollTop = @getNewScrollTop(count)
      super(count)
      @editorElement.setScrollTop(scrollTop)

  moveCursor: (cursor) ->
    cursor.setScreenPosition(Point(@cursorRow, 0), autoscroll: false)

  # TODO: remove this method once after Atom v1.1.0 is released.
  getNewScrollTop: (count=1) ->
    currentScrollTop = @editorElement.component.presenter.pendingScrollTop ? @editorElement.getScrollTop()
    currentCursorRow = @editor.getCursorScreenPosition().row
    rowsPerPage = @editor.getRowsPerPage()
    lineHeight = @editor.getLineHeightInPixels()
    scrollRows = Math.floor(@pageScrollFraction * rowsPerPage * count)
    @cursorRow = currentCursorRow + scrollRows
    currentScrollTop + scrollRows * lineHeight

  getNewFirstVisibleScreenRow: (count=1) ->
    currentTopRow = @editor.getFirstVisibleScreenRow()
    currentCursorRow = @editor.getCursorScreenPosition().row
    rowsPerPage = @editor.getRowsPerPage()
    scrollRows = Math.ceil(@pageScrollFraction * rowsPerPage * count)
    @cursorRow = currentCursorRow + scrollRows
    currentTopRow + scrollRows

class ScrollHalfUpKeepCursor extends ScrollKeepingCursor
  pageScrollFraction: -1 / 2

class ScrollFullUpKeepCursor extends ScrollKeepingCursor
  pageScrollFraction: -1

class ScrollHalfDownKeepCursor extends ScrollKeepingCursor
  pageScrollFraction: 1 / 2

class ScrollFullDownKeepCursor extends ScrollKeepingCursor
  pageScrollFraction: 1

module.exports = {
  Motion, MotionWithInput, CurrentSelection, MoveLeft, MoveRight, MoveUp, MoveDown,
  MoveToPreviousWord, MoveToPreviousWholeWord, MoveToNextWord, MoveToNextWholeWord,
  MoveToEndOfWord, MoveToNextSentence, MoveToPreviousSentence, MoveToNextParagraph, MoveToPreviousParagraph, MoveToAbsoluteLine, MoveToRelativeLine, MoveToBeginningOfLine,
  MoveToFirstCharacterOfLineUp, MoveToFirstCharacterOfLineDown,
  MoveToFirstCharacterOfLine, MoveToFirstCharacterOfLineAndDown, MoveToLastCharacterOfLine,
  MoveToLastNonblankCharacterOfLineAndDown, MoveToStartOfFile,
  MoveToTopOfScreen, MoveToBottomOfScreen, MoveToMiddleOfScreen, MoveToEndOfWholeWord, MotionError,
  ScrollHalfUpKeepCursor, ScrollFullUpKeepCursor,
  ScrollHalfDownKeepCursor, ScrollFullDownKeepCursor
}
