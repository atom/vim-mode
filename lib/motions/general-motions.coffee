_ = require 'underscore-plus'
{Point, Range} = require 'atom'


class MotionError
  constructor: (@message) ->
    @name = 'Motion Error'

class Motion
  constructor: (@editor, @vimState) ->
    @vimState.desiredCursorColumn = null

  isComplete: -> true
  isRecordable: -> false
  inVisualMode: -> @vimState.mode == "visual"

  setCursorBufferPositions: (editor, positions) =>
    first = true
    for position in positions
      if first
        @editor.setCursorBufferPosition(position)
        first = false
      else
        @editor.addCursorAtBufferPosition(position)

class CurrentSelection extends Motion
  constructor: (@editor, @vimState) ->
    super(@editor, @vimState)
    @selection = @editor.getSelectedBufferRanges()

  execute: (count=1) ->
    _.times(count, -> true)

  select: (count=1) ->
    @editor.setSelectedBufferRanges(@selection)
    _.times(count, -> true)

  isLinewise: -> @vimState.mode == 'visual' and @vimState.submode == 'linewise'

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
  execute: (count=1) ->
    _.times count, =>
      newPositions = @editor.getCursorBufferPositions().map (position) =>
        [position.row, Math.max(position.column - 1, 0)]
      @setCursorBufferPositions(@editor, newPositions)

  select: (count=1) ->
    _.times count, =>
      {column} = @editor.getCursorBufferPosition()

      if column > 0
        @editor.selectLeft()
        true
      else
        false

class MoveRight extends Motion
  execute: (count=1) ->
    _.times count, =>
      newPositions = @editor.getCursorBufferPositions().map (position) =>
        lastPosition = @editor.lineTextForBufferRow(position.row).length - 1
        [position.row, Math.min(position.column + 1, lastPosition)]
      @setCursorBufferPositions(@editor, newPositions)

  select: (count=1) ->
    _.times count, =>
      {start, end} = @editor.getSelectedBufferRange()
      rowLength = @editor.getLastCursor().getCurrentBufferLine().length

      if end.column < rowLength
        @editor.selectRight()
        true
      else
        false

class MoveVertically extends Motion

  constructor: (@editor, @vimState) ->
    # 'desiredCursorColumn' gets overwritten in the Motion constructor,
    # so we need to re-set it after calling super.
    column = @vimState.desiredCursorColumn
    super(@editor, @vimState)
    @vimState.desiredCursorColumn = column

  isLinewise: -> @vimState.mode == 'visual' and @vimState.submode == 'linewise'

  execute: (count=1) ->
    {row, column} = @editor.getCursorBufferPosition()

    nextRow = @nextValidRow(count)

    if nextRow != row
      nextLineLength = @editor.lineTextForBufferRow(nextRow).length

      # The 'nextColumn' the cursor should be in is the
      # 'desiredCursorColumn', if it exists. If it does
      # not, the current column should be used.
      nextColumn = @vimState.desiredCursorColumn || column

      # Check to see if the 'nextColumn' position of
      # cursor is greater than or equal to the length
      # of the next line.
      if nextColumn >= nextLineLength
        # When the 'nextColumn' is greater than the
        # length of the next line, we should move the
        # cursor to the end of the next line and save
        # 'nextColumn' in 'desiredCursorColumn'.
        @editor.setCursorBufferPosition([nextRow, nextLineLength-1])
        @vimState.desiredCursorColumn = nextColumn
      else
        # When the 'nextColumn' is a valid spot to
        # move into, in the next line, simply move
        # there and unset 'desiredCursorColumn'.
        @editor.setCursorBufferPosition([nextRow, nextColumn])
        @vimState.desiredCursorColumn = null

  # Internal: Finds the next valid row that can be moved
  # to. This move takes folded lines into account when
  # calculating the next valid row.
  #
  # count - The number of folded 'buffer' rows away from
  #         the current row.
  #
  # Returns an integer row index.
  nextValidRow: (count) ->
    {row, column} = @editor.getCursorBufferPosition()

    maxRow = @editor.getLastBufferRow()
    minRow = 0

    # For each count, add 1 'directionIncrement' to
    # row. Folded rows count as a single row.
    _.times count, =>
      if @editor.isFoldedAtBufferRow(row)
        while @editor.isFoldedAtBufferRow(row)
          row += @directionIncrement()
      else
        row += @directionIncrement()

    if row > maxRow
      maxRow
    else if row < minRow
      minRow
    else
      row

class MoveUp extends MoveVertically
  # Internal: The direction to move the cursor. Use -1
  # for moving up, 1 for moving down.
  #
  # Returns -1
  directionIncrement: ->
    -1

  select: (count=1) ->
    unless @inVisualMode()
      @editor.moveToBeginningOfLine()
      @editor.moveDown()
      @editor.selectUp()

    _.times count, =>
      if @isLinewise()
        selection = @editor.getLastSelection()
        range = selection.getBufferRange().copy()
        if range.coversSameRows(@vimState.initialSelectedRange)
          range.start.row--
        else
          if range.start.row < @vimState.initialSelectedRange.start.row
            range.start.row--
          else
            range.end.row--

        selection.setBufferRange(range)
      else
        @editor.selectUp()
      true

class MoveDown extends MoveVertically
  # Internal: The direction to move the cursor. Use -1
  # for moving up, 1 for moving down.
  #
  # Returns 1
  directionIncrement: ->
    1

  select: (count=1) ->
    @editor.selectLinesContainingCursors() unless @inVisualMode()

    _.times count, =>
      if @isLinewise()
        selection = @editor.getLastSelection()
        range = selection.getBufferRange().copy()
        if range.start.row < @vimState.initialSelectedRange.start.row
          range.start.row++
        else
          range.end.row++

        selection.setBufferRange(range)
      else
        @editor.selectDown()

      true

class MoveToPreviousWord extends Motion
  execute: (count=1) ->
    _.times count, =>
      @editor.moveToBeginningOfWord()

  select: (count=1) ->
    _.times count, =>
      @editor.selectToBeginningOfWord()
      true

class MoveToPreviousWholeWord extends Motion
  execute: (count=1) ->
    _.times count, =>
      @editor.moveToBeginningOfWord()
      @editor.moveToBeginningOfWord() while not @isWholeWord() and not @isBeginningOfFile()

  select: (count=1) ->
    _.times count, =>
      @editor.selectToBeginningOfWord()
      @editor.selectToBeginningOfWord() while not @isWholeWord() and not @isBeginningOfFile()
      true

  isWholeWord: ->
    char = @editor.getLastCursor().getCurrentWordPrefix().slice(-1)
    char is ' ' or char is '\n'

  isBeginningOfFile: ->
    cur = @editor.getCursorBufferPosition();
    not cur.row and not cur.column

class MoveToNextWord extends Motion
  execute: (count=1) ->
    cursor = @editor.getLastCursor()

    _.times count, =>
      current = cursor.getBufferPosition()
      next = cursor.getBeginningOfNextWordBufferPosition()

      return if @isEndOfFile()

      if cursor.isAtEndOfLine()
        cursor.moveDown()
        cursor.moveToBeginningOfLine()
        cursor.skipLeadingWhitespace()
      else if current.row is next.row and current.column is next.column
        cursor.moveToEndOfWord()
      else
        cursor.moveToBeginningOfNextWord()

  # Options
  #  excludeWhitespace - if true, whitespace shouldn't be selected
  select: (count=1, {excludeWhitespace}={}) ->
    cursor = @editor.getLastCursor()

    _.times count, =>
      current = cursor.getBufferPosition()
      next = cursor.getBeginningOfNextWordBufferPosition()

      if current.row != next.row or excludeWhitespace or current == next
        @editor.selectToEndOfWord()
      else
        @editor.selectToBeginningOfNextWord()

      true

  isEndOfFile: ->
    cur = @editor.getLastCursor().getBufferPosition()
    eof = @editor.getEofBufferPosition()
    cur.row is eof.row and cur.column is eof.column

class MoveToNextWholeWord extends Motion
  execute: (count=1) ->
    _.times count, =>
      @editor.moveToBeginningOfNextWord()
      @editor.moveToBeginningOfNextWord() while not @isWholeWord() and not @isEndOfFile()

  select: (count=1, {excludeWhitespace}={}) ->
    cursor = @editor.getLastCursor()

    _.times count, =>
      current = cursor.getBufferPosition()
      next = cursor.getBeginningOfNextWordBufferPosition(/[^\s]/)

      if current.row != next.row or excludeWhitespace
        @editor.selectToEndOfWord()
      else
        @editor.selectToBeginningOfNextWord()
        @editor.selectToBeginningOfNextWord() while not @isWholeWord() and not @isEndOfFile()

      true

  isWholeWord: ->
    char = @editor.getLastCursor().getCurrentWordPrefix().slice(-1)
    char is ' ' or char is '\n'

  isEndOfFile: ->
    last = @editor.getEofBufferPosition()
    cur = @editor.getCursorBufferPosition()
    last.row is cur.row and last.column is cur.column

class MoveToEndOfWord extends Motion
  execute: (count=1) ->
    cursor = @editor.getLastCursor()
    _.times count, =>
      cursor.setBufferPosition(@nextBufferPosition(exclusive: true))

  select: (count=1) ->
    cursor = @editor.getLastCursor()

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
    cursor = @editor.getLastCursor()
    current = cursor.getBufferPosition()
    next = cursor.getEndOfCurrentWordBufferPosition()
    next.column -= 1 if exclusive

    if exclusive and current.row == next.row and current.column == next.column
      cursor.moveRight()
      next = cursor.getEndOfCurrentWordBufferPosition()
      next.column -= 1

    next

class MoveToEndOfWholeWord extends Motion
  execute: (count=1) ->
    cursor = @editor.getLastCursor()
    _.times count, =>
      cursor.setBufferPosition(@nextBufferPosition(exclusive: true))

  select: (count=1) ->
    _.times count, =>
      bufferPosition = @nextBufferPosition()
      screenPosition = @editor.screenPositionForBufferPosition(bufferPosition)
      @editor.selectToScreenPosition(screenPosition)
      true

  # Private: Finds the end of the current whole word and stops on the last character
  #
  # exclusive - If true will stop on the last character of the whole word rather
  #             than the next character after the word.
  nextBufferPosition: ({exclusive}={})->
    # get next position and reset cursor's position
    {row, column} = @editor.getCursorBufferPosition()
    start = new Point(row, column + 1)

    scanRange = [start, @editor.getEofBufferPosition()]
    position = @editor.getEofBufferPosition()

    @editor.scanInBufferRange /\S+/, scanRange, ({range, stop}) =>
      position = range.end
      stop()

    position.column -= 1 if exclusive
    position

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
    @setCursorPosition(count)
    @editor.getLastCursor().skipLeadingWhitespace()

  # Options
  #  requireEOL - if true, ensure an end of line character is always selected
  select: (count=@editor.getLineCount(), {requireEOL}={}) ->
    {row, column} = @editor.getCursorBufferPosition()
    if row >= count
      start = count - 1
      end = row
    else
      start = row
      end = count - 1
    @editor.setSelectedBufferRange(@selectRows(start, end, {requireEOL}))

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
     if end >= buffer.getLastRow()
       end = buffer.getLastRow()
       if start > 0 and requireEOL and start == end
         startPoint = [start - 1, buffer.lineLengthForRow(start - 1)]
       else
         startPoint = [start, 0]
       endPoint = [end, buffer.lineLengthForRow(end)]
     else
       startPoint = [start, 0]
       endPoint = [end + 1, 0]

      new Range(startPoint, endPoint)

  setCursorPosition: (count) ->
    @editor.setCursorBufferPosition([@getDestinationRow(count), 0])

  getDestinationRow: (count) ->
    if count? then count - 1 else (@editor.getLineCount() - 1)

class MoveToRelativeLine extends MoveToLine
  # Options
  #  requireEOL - if true, ensure an end of line character is always selected
  select: (count=1, {requireEOL}={}) ->
    {row, column} = @editor.getCursorBufferPosition()
    @editor.setSelectedBufferRange(@selectRows(row, row + (count - 1), {requireEOL}))

    _.times count, ->
      true

class MoveToScreenLine extends MoveToLine
  constructor: (@editor, @vimState, @scrolloff) ->
    @scrolloff = 2 # atom default
    super(@editor, @vimState)

  setCursorPosition: (count) ->
    @editor.setCursorScreenPosition([@getDestinationRow(count), 0])

class MoveToBeginningOfLine extends Motion
  execute: (count=1) ->
    @editor.moveToBeginningOfLine()

  select: (count=1) ->
    _.times count, =>
      @editor.selectToBeginningOfLine()
      true

class MoveToFirstCharacterOfLine extends Motion
  constructor:(@editor, @vimState) ->
    @cursor = @editor.getLastCursor()
    super(@editor, @vimState)

  execute: () ->
    @editor.setCursorBufferPosition([@cursor.getBufferRow(), @getDestinationColumn()])

  select: (count=1) ->
    if @getDestinationColumn() isnt @cursor.getBufferColumn()
      _.times count, =>
        @editor.selectToFirstCharacterOfLine()
        true

  getDestinationColumn: ->
    @editor.lineTextForBufferRow(@cursor.getBufferRow()).search(/\S/)

class MoveToLastCharacterOfLine extends Motion
  execute: (count=1) ->
    # After moving to the end of the line, vertical motions
    # should stay at the last column.
    @vimState.desiredCursorColumn = Infinity

    _.times count, =>
      @editor.moveToEndOfLine()
      @editor.moveLeft() unless @editor.getLastCursor().getBufferColumn() is 0

  select: (count=1) ->
    _.times count, =>
      @editor.selectToEndOfLine()
      true

class MoveToFirstCharacterOfLineUp extends Motion
  execute: (count=1) ->
    (new MoveUp(@editor, @vimState)).execute(count)
    (new MoveToFirstCharacterOfLine(@editor, @vimState)).execute()

  select: (count=1) ->
    (new MoveUp(@editor, @vimState)).select(count)

class MoveToFirstCharacterOfLineDown extends Motion
  execute: (count=1) ->
    (new MoveDown(@editor, @vimState)).execute(count)
    (new MoveToFirstCharacterOfLine(@editor, @vimState)).execute()

  select: (count=1) ->
    (new MoveDown(@editor, @vimState)).select(count)

class MoveToStartOfFile extends MoveToLine
  isLinewise: -> @vimState.mode == 'visual' and @vimState.submode == 'linewise'

  getDestinationRow: (count=1) ->
    count - 1

  getDestinationColumn: (row) ->
    if @isLinewise() then 0 else @editor.lineTextForBufferRow(row).search(/\S/)

  getStartingColumn: (column) ->
    if @isLinewise() then column else column + 1

  select: (count=1) ->
    {row, column} = @editor.getCursorBufferPosition()
    startingCol = @getStartingColumn(column)
    destinationRow = @getDestinationRow(count)
    destinationCol = @getDestinationColumn(destinationRow)
    bufferRange = new Range([row, startingCol], [destinationRow, destinationCol])
    @editor.setSelectedBufferRange(bufferRange, reversed: true)

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
  MoveToEndOfWord, MoveToNextParagraph, MoveToPreviousParagraph, MoveToLine, MoveToRelativeLine, MoveToBeginningOfLine,
  MoveToFirstCharacterOfLineUp, MoveToFirstCharacterOfLineDown,
  MoveToFirstCharacterOfLine, MoveToLastCharacterOfLine, MoveToStartOfFile, MoveToTopOfScreen,
  MoveToBottomOfScreen, MoveToMiddleOfScreen, MoveToEndOfWholeWord, MotionError
}
