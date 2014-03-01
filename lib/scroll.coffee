{Point, Range} = require 'atom'

class Scroll
  constructor: (@editorView, @editor) ->
  isComplete: -> true
  isRecordable: -> false

class ScrollDown extends Scroll
  constructor: (@editorView, @editor, @scrolloff) ->
    super(@editorView, @editor)

  execute: (count=1) ->
    lastRow = @editorView.getLastVisibleScreenRow() - @scrolloff
    firstRow = @editorView.getFirstVisibleScreenRow() + @scrolloff
    [cursorRow, cursorColumn] = @editor.getCursorBufferPosition().toArray()

    if cursorRow - count <= firstRow
      @editor.setCursorBufferPosition([firstRow + count, cursorColumn])
    @editorView.scrollToBufferPosition([lastRow + count, cursorColumn])


class ScrollUp extends Scroll
  constructor: (@editorView, @editor, @scrolloff) ->
    super(@editorView, @editor)

  execute: (count=1) ->
    lastRow = @editorView.getLastVisibleScreenRow() - @scrolloff
    firstRow = @editorView.getFirstVisibleScreenRow() + @scrolloff
    [cursorRow, cursorColumn] = @editor.getCursorBufferPosition().toArray()

    if cursorRow + count >= lastRow
      @editor.setCursorBufferPosition([lastRow - count, cursorColumn])
    @editorView.scrollToBufferPosition([firstRow - count, cursorColumn])

module.exports = { ScrollDown, ScrollUp }
