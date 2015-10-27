{Range} = require 'atom'
AllWhitespace = /^\s$/
WholeWordRegex = /\S+/
{mergeRanges} = require './utils'

class TextObject
  constructor: (@editor, @state) ->

  isComplete: -> true
  isRecordable: -> false

  execute: -> @select.apply(this, arguments)

class SelectInsideWord extends TextObject
  select: ->
    for selection in @editor.getSelections()
      if selection.isEmpty()
        selection.selectRight()
      selection.expandOverWord()
    [true]

class SelectInsideWholeWord extends TextObject
  select: ->
    for selection in @editor.getSelections()
      range = selection.cursor.getCurrentWordBufferRange({wordRegex: WholeWordRegex})
      selection.setBufferRange(mergeRanges(selection.getBufferRange(), range))
      true

# SelectInsideQuotes and the next class defined (SelectInsideBrackets) are
# almost-but-not-quite-repeated code. They are different because of the depth
# checks in the bracket matcher.

class SelectInsideQuotes extends TextObject
  constructor: (@editor, @char, @includeQuotes) ->

  findOpeningQuote: (pos) ->
    start = pos.copy()
    pos = pos.copy()
    while pos.row >= 0
      line = @editor.lineTextForBufferRow(pos.row)
      pos.column = line.length - 1 if pos.column is -1
      while pos.column >= 0
        if line[pos.column] is @char
          if pos.column is 0 or line[pos.column - 1] isnt '\\'
            if @isStartQuote(pos)
              return pos
            else
              return @lookForwardOnLine(start)
        -- pos.column
      pos.column = -1
      -- pos.row
    @lookForwardOnLine(start)

  isStartQuote: (end) ->
    line = @editor.lineTextForBufferRow(end.row)
    numQuotes = line.substring(0, end.column + 1).replace( "'#{@char}", '').split(@char).length - 1
    numQuotes % 2

  lookForwardOnLine: (pos) ->
    line = @editor.lineTextForBufferRow(pos.row)

    index = line.substring(pos.column).indexOf(@char)
    if index >= 0
      pos.column += index
      return pos
    null

  findClosingQuote: (start) ->
    end = start.copy()
    escaping = false

    while end.row < @editor.getLineCount()
      endLine = @editor.lineTextForBufferRow(end.row)
      while end.column < endLine.length
        if endLine[end.column] is '\\'
          ++ end.column
        else if endLine[end.column] is @char
          -- start.column if @includeQuotes
          ++ end.column if @includeQuotes
          return end
        ++ end.column
      end.column = 0
      ++ end.row
    return

  select: ->
    for selection in @editor.getSelections()
      start = @findOpeningQuote(selection.cursor.getBufferPosition())
      if start?
        ++ start.column # skip the opening quote
        end = @findClosingQuote(start)
        if end?
          selection.setBufferRange(mergeRanges(selection.getBufferRange(), [start, end]))
      not selection.isEmpty()

# SelectInsideBrackets and the previous class defined (SelectInsideQuotes) are
# almost-but-not-quite-repeated code. They are different because of the depth
# checks in the bracket matcher.

class SelectInsideBrackets extends TextObject
  constructor: (@editor, @beginChar, @endChar, @includeBrackets) ->

  findOpeningBracket: (pos) ->
    pos = pos.copy()
    depth = 0
    while pos.row >= 0
      line = @editor.lineTextForBufferRow(pos.row)
      pos.column = line.length - 1 if pos.column is -1
      while pos.column >= 0
        switch line[pos.column]
          when @endChar then ++ depth
          when @beginChar
            return pos if -- depth < 0
        -- pos.column
      pos.column = -1
      -- pos.row

  findClosingBracket: (start) ->
    end = start.copy()
    depth = 0
    while end.row < @editor.getLineCount()
      endLine = @editor.lineTextForBufferRow(end.row)
      while end.column < endLine.length
        switch endLine[end.column]
          when @beginChar then ++ depth
          when @endChar
            if -- depth < 0
              -- start.column if @includeBrackets
              ++ end.column if @includeBrackets
              return end
        ++ end.column
      end.column = 0
      ++ end.row
    return

  select: ->
    for selection in @editor.getSelections()
      start = @findOpeningBracket(selection.cursor.getBufferPosition())
      if start?
        ++ start.column # skip the opening quote
        end = @findClosingBracket(start)
        if end?
          selection.setBufferRange(mergeRanges(selection.getBufferRange(), [start, end]))
      not selection.isEmpty()

class SelectAWord extends TextObject
  select: ->
    for selection in @editor.getSelections()
      if selection.isEmpty()
        selection.selectRight()
      selection.expandOverWord()
      loop
        endPoint = selection.getBufferRange().end
        char = @editor.getTextInRange(Range.fromPointWithDelta(endPoint, 0, 1))
        break unless AllWhitespace.test(char)
        selection.selectRight()
      true

class SelectAWholeWord extends TextObject
  select: ->
    for selection in @editor.getSelections()
      range = selection.cursor.getCurrentWordBufferRange({wordRegex: WholeWordRegex})
      selection.setBufferRange(mergeRanges(selection.getBufferRange(), range))
      loop
        endPoint = selection.getBufferRange().end
        char = @editor.getTextInRange(Range.fromPointWithDelta(endPoint, 0, 1))
        break unless AllWhitespace.test(char)
        selection.selectRight()
      true

class Paragraph extends TextObject

  select: ->
    for selection in @editor.getSelections()
      @selectParagraph(selection)

  # Return a range delimted by the start or the end of a paragraph
  paragraphDelimitedRange: (startPoint) ->
    inParagraph = @isParagraphLine(@editor.lineTextForBufferRow(startPoint.row))
    upperRow = @searchLines(startPoint.row, -1, inParagraph)
    lowerRow = @searchLines(startPoint.row, @editor.getLineCount(), inParagraph)
    new Range([upperRow + 1, 0], [lowerRow, 0])

  searchLines: (startRow, rowLimit, startedInParagraph) ->
    for currentRow in [startRow..rowLimit]
      line = @editor.lineTextForBufferRow(currentRow)
      if startedInParagraph isnt @isParagraphLine(line)
        return currentRow
    rowLimit

  isParagraphLine: (line) -> (/\S/.test(line))

class SelectInsideParagraph extends Paragraph
  selectParagraph: (selection) ->
    oldRange = selection.getBufferRange()
    startPoint = selection.cursor.getBufferPosition()
    newRange = @paragraphDelimitedRange(startPoint)
    selection.setBufferRange(mergeRanges(oldRange, newRange))
    true

class SelectAParagraph extends Paragraph
  selectParagraph: (selection) ->
    oldRange = selection.getBufferRange()
    startPoint = selection.cursor.getBufferPosition()
    newRange = @paragraphDelimitedRange(startPoint)
    nextRange = @paragraphDelimitedRange(newRange.end)
    selection.setBufferRange(mergeRanges(oldRange, [newRange.start, nextRange.end]))
    true

module.exports = {TextObject, SelectInsideWord, SelectInsideWholeWord, SelectInsideQuotes,
  SelectInsideBrackets, SelectAWord, SelectAWholeWord, SelectInsideParagraph, SelectAParagraph}
