class Scroll
  constructor: (@editorView, @editor) ->
  isComplete: -> true
  isRecordable: -> false

class ScrollDown extends Scroll
  constructor: (@editorView, @editor, @scrolloff) ->
    super(@editorView, @editor)

  execute: (count=1) ->
    @keepCursorOnScreen(count)
    @scrollUp(count)

  keepCursorOnScreen: (count) ->
    {row, column} = @editor.getCursorBufferPosition()
    firstScreenRow = @editorView.getFirstVisibleScreenRow() + @scrolloff
    if row - count <= firstScreenRow
      @editor.setCursorBufferPosition([firstScreenRow + count, column])

  scrollUp: (count) ->
    lastScreenRow = @editorView.getLastVisibleScreenRow() - @scrolloff
    @editorView.scrollToBufferPosition([lastScreenRow + count, 0])

class ScrollUp extends Scroll
  constructor: (@editorView, @editor, @scrolloff) ->
    super(@editorView, @editor)

  execute: (count=1) ->
    @keepCursorOnScreen(count)
    @scrollDown(count)

  keepCursorOnScreen: (count) ->
    {row, column} = @editor.getCursorBufferPosition()
    lastScreenRow = @editorView.getLastVisibleScreenRow() - @scrolloff
    if row + count >= lastScreenRow
        @editor.setCursorBufferPosition([lastScreenRow - count, column])

  scrollDown: (count) ->
    firstScreenRow = @editorView.getFirstVisibleScreenRow() + @scrolloff
    @editorView.scrollToBufferPosition([firstScreenRow - count, 0])

module.exports = { ScrollDown, ScrollUp }
