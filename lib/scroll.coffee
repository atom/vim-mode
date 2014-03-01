{Point, Range} = require 'atom'

class Scroll
  constructor: (@editorView, @editor) ->
  isComplete: -> true
  isRecordable: -> false

class ScrollDown extends Scroll
  constructor: (@editorView, @editor, @scrolloff) ->
    super(@editorView, @editor)

  execute: (count=1) ->
    {row, column} = @editor.getCursorBufferPosition()
    lastRow = @editorView.getLastVisibleScreenRow() - @scrolloff
    firstRow = @editorView.getFirstVisibleScreenRow() + @scrolloff

    if row - count <= firstRow
      @editor.setCursorBufferPosition([firstRow + count, column])
    @editorView.scrollToBufferPosition([lastRow + count, column])


class ScrollUp extends Scroll
  constructor: (@editorView, @editor, @scrolloff) ->
    super(@editorView, @editor)

  execute: (count=1) ->
    {row, column} = @editor.getCursorBufferPosition()
    lastRow = @editorView.getLastVisibleScreenRow() - @scrolloff
    firstRow = @editorView.getFirstVisibleScreenRow() + @scrolloff

    if row + count >= lastRow
      @editor.setCursorBufferPosition([lastRow - count, column])
    @editorView.scrollToBufferPosition([firstRow - count, column])

module.exports = { ScrollDown, ScrollUp }
