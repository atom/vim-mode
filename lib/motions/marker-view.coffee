{$} = require 'atom'

module.exports =
class MarkerView

  constructor: (range,  editor, searcher) ->
    @searcher = searcher
    @range = range
    @editor = editor
    @element = document.createElement('div')
    @element.className = 'marker'
    rowSpan = range.end.row - range.start.row

    if rowSpan == 0
      @appendRegion(1, range.start, range.end)
    else
      @appendRegion(1, range.start, null)
      if rowSpan > 1
        @appendRegion(rowSpan - 1, { row: range.start.row + 1, column: 0}, null)
      @appendRegion(1, { row: range.end.row, column: 0 }, range.end)

  appendRegion: (rows, start, end) ->
    { lineHeight, charWidth } = @editor
    css = @editor.pixelPositionForScreenPosition(start)
    css.height = lineHeight * rows
    if end
      css.width = @editor.pixelPositionForScreenPosition(end).left - css.left
    else
      css.right = 0

    region = document.createElement('div')
    region.className = 'region'
    for name, value of css
      region.style[name] = value + 'px'

    @element.appendChild(region)
