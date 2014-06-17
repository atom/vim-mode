class TextObject
  constructor: (@editor, @state) ->

  isComplete: -> true
  isRecordable: -> false

class SelectInsideWord extends TextObject
  select: ->
    @editor.selectWord()
    [true]

# SelectInsideQuotes and the next class defined (SelectInsideBrackets) are
# almost-but-not-quite-repeated code. They are different because of the depth
# checks in the bracket matcher.

class SelectInsideQuotes extends TextObject
  constructor: (@editor, @char) ->

  findOpeningQuote: (pos) ->
    pos = pos.copy()
    while pos.row >= 0
      line = @editor.lineForBufferRow(pos.row)
      pos.column = line.length - 1 if pos.column == -1
      while pos.column >= 0
        if line[pos.column] == @char
          return pos if pos.column == 0 or line[pos.column - 1] != '\\'
        -- pos.column
      pos.column = -1
      -- pos.row

  findClosingQuote: (start) ->
    end = start.copy()
    escaping = false

    while end.row < @editor.getLineCount()
      endLine = @editor.lineForBufferRow(end.row)
      while end.column < endLine.length
        if endLine[end.column] == '\\'
          ++ end.column
        else if endLine[end.column] == @char
          @editor.expandSelectionsForward (selection) =>
            selection.cursor.setBufferPosition start
            selection.selectToBufferPosition end
          return {select:[true], end:end}
        ++ end.column
      end.column = 0
      ++ end.row

    {select:[false], end:end}

  select: ->
    start = @findOpeningQuote(@editor.getCursorBufferPosition())
    return [false] unless start?

    ++ start.column  # skip the opening quote

    {select,end} = @findClosingQuote(start)
    select

# SelectInsideBrackets and the previous class defined (SelectInsideQuotes) are
# almost-but-not-quite-repeated code. They are different because of the depth
# checks in the bracket matcher.

class SelectInsideBrackets extends TextObject
  constructor: (@editor, @beginChar, @endChar) ->

  findOpeningBracket: (pos) ->
    pos = pos.copy()
    depth = 0
    while pos.row >= 0
      line = @editor.lineForBufferRow(pos.row)
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
      endLine = @editor.lineForBufferRow(end.row)
      while end.column < endLine.length
        switch endLine[end.column]
          when @beginChar then ++ depth
          when @endChar
            if -- depth < 0
              @editor.expandSelectionsForward (selection) =>
                selection.cursor.setBufferPosition start
                selection.selectToBufferPosition end
              return {select:[true], end:end}
        ++ end.column
      end.column = 0
      ++ end.row

    {select:[false], end:end}

  select: ->
    start = @findOpeningBracket(@editor.getCursorBufferPosition())
    return [false] unless start?
    ++ start.column  # skip the opening bracket
    {select,end} = @findClosingBracket(start)
    select

module.exports = {TextObject, SelectInsideWord, SelectInsideQuotes, SelectInsideBrackets}
