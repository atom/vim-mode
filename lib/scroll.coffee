class Scroll
  isComplete: -> true
  isRecordable: -> false
  constructor: (@editorView, @editor) ->
    @scrolloff = 2 # atom default

class ScrollDown extends Scroll
  execute: (count=1) ->
    @keepCursorOnScreen(count)
    @scrollUp(count)

  keepCursorOnScreen: (count) ->
    {row, column} = @editor.getCursorScreenPosition()
    firstScreenRow = @editorView.getFirstVisibleScreenRow() + @scrolloff + 1
    if row - count <= firstScreenRow
      @editor.setCursorScreenPosition([firstScreenRow + count, column])

  scrollUp: (count) ->
    lastScreenRow = @editorView.getLastVisibleScreenRow() - @scrolloff
    @editorView.scrollToScreenPosition([lastScreenRow + count, 0])

class ScrollUp extends Scroll
  execute: (count=1) ->
    @keepCursorOnScreen(count)
    @scrollDown(count)

  keepCursorOnScreen: (count) ->
    {row, column} = @editor.getCursorScreenPosition()
    lastScreenRow = @editorView.getLastVisibleScreenRow() - @scrolloff - 1
    if row + count >= lastScreenRow
        @editor.setCursorScreenPosition([lastScreenRow - count, column])

  scrollDown: (count) ->
    firstScreenRow = @editorView.getFirstVisibleScreenRow() + @scrolloff
    @editorView.scrollToScreenPosition([firstScreenRow - count, 0])

module.exports = { ScrollDown, ScrollUp }
