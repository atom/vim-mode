{Point, Range} = require 'atom'
ViewModel = require './view-model'

module.exports =
class FindViewModel extends ViewModel
  constructor: (@findMotion) ->
    super(@findMotion, class: 'find', singleChar: true, hidden: true)
    @reversed = false

  reverse: -> @reversed = !@reversed

  match: (count) ->
    currentPosition = @editorView.editor.getCursorBufferPosition()
    line = @editorView.editor.lineForBufferRow(currentPosition.row)
    if @reversed
      index = currentPosition.column
      for i in [0..count-1]
        index = line.lastIndexOf(@value, index-1)
      if index != -1
        point = new Point(currentPosition.row, index)
        return {} =
          point: point
          range: new Range(point, currentPosition)
    else
      index = currentPosition.column
      for i in [0..count-1]
        index = line.indexOf(@value, index+1)
      if index != -1
        point = new Point(currentPosition.row, index)
        return {} =
          point: point
          range: new Range(currentPosition, point.translate([0,1]))

  execute: (@value, count) ->
    if (match = @match(count))?
      @editorView.editor.setCursorBufferPosition(match.point)

  select: (@value, count, requireEOL) ->
    if (match = @match(count))?
      @editorView.editor.setSelectedBufferRange(match.range)
      return [true]
    [false]
