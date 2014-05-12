
class TextObject
  constructor: (@editor, @state) ->

  isComplete: -> true
  isRecordable: -> false

class SelectInsideWord extends TextObject
  select: ->
    @editor.selectWord()
    [true]

class SelectInsideQuotes extends TextObject
  constructor: (@editor, @char) ->
  select: ->
    start = @editor.getCursorBufferPosition().copy()

    return [false] unless (=>
      while start.row >= 0
        startLine = @editor.lineForBufferRow(start.row)
        start.column = startLine.length - 1 if start.column == -1
        while start.column >= 0
          if startLine[start.column] == @char
            return true if start.column == 0 or startLine[start.column - 1] != '\\'
          -- start.column
        start.column = -1
        -- start.row
    )()
     
    ++ start.column  # skip the opening quote
     
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
          return [true]
        ++ end.column
      end.column = 0
      ++ end.row
    
    [false]

class SelectInsideBrackets extends TextObject
  constructor: (@editor, @beginChar, @endChar) ->
  select: ->
    start = @editor.getCursorBufferPosition().copy()
    depth = 0
             
    return [false] unless (=>
      while start.row >= 0
        startLine = @editor.lineForBufferRow(start.row)
        start.column = startLine.length - 1 if start.column == -1
        while start.column >= 0
          switch startLine[start.column]
            when @endChar then ++ depth
            when @beginChar
              return true if -- depth < 0
          -- start.column
        start.column = -1
        -- start.row
    )()
     
    ++ start.column  # skip the opening bracket
     
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
              return [true]
        ++ end.column
      end.column = 0
      ++ end.row
    
    [false]

module.exports = {SelectInsideWord, SelectInsideQuotes, SelectInsideBrackets}

