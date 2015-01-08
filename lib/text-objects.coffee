{Range} = require 'atom'
AllWhitespace = /^\s$/

class TextObject
  constructor: (@editor, @state) ->

  isComplete: -> true
  isRecordable: -> false

class SelectInsideWord extends TextObject
  select: ->
    @editor.selectWordsContainingCursors()
    [true]

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
      pos.column = line.length - 1 if pos.column == -1
      while pos.column >= 0
        if line[pos.column] == @char
          if pos.column == 0 or line[pos.column - 1] != '\\'
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
        if endLine[end.column] == '\\'
          ++ end.column
        else if endLine[end.column] == @char
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
          selection.setBufferRange([start, end])
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
      pos.column = line.length - 1 if pos.column == -1
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
          selection.setBufferRange([start, end])
      not selection.isEmpty()

class SelectAWord extends TextObject
  select: ->
    for selection in @editor.getSelections()
      selection.selectWord()
      loop
        endPoint = selection.getBufferRange().end
        char = @editor.getTextInRange(Range.fromPointWithDelta(endPoint, 0, 1))
        break unless AllWhitespace.test(char)
        selection.selectRight()
      true

module.exports = {TextObject, SelectInsideWord, SelectInsideQuotes, SelectInsideBrackets, SelectAWord}
