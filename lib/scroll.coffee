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

class ScrollToScreenMiddle extends Scroll
  execute: (count=1) ->
    @scrollToScreenMiddle(count)

  scrollToScreenMiddle: (count) ->
    {row, column} = @editor.getCursorScreenPosition()
    firstScreenRow = @editorView.getFirstVisibleScreenRow()
    halfScreenRange = Math.floor(@editor.getRowsPerPage() / 2)
    if row < (firstScreenRow + halfScreenRange)
      destRow = row - halfScreenRange + @scrolloff
      if destRow < 0
        destRow = 0
      @editorView.scrollToScreenPosition([destRow, 0])
    else
      lastBufferRow = @editor.getLastBufferRow()
      destRow = row + halfScreenRange - @scrolloff
      if destRow > lastBufferRow
        destRow = lastBufferRow
      @editorView.scrollToScreenPosition([destRow, 0])

class ScrollToScreenTop extends Scroll
  execute: (count=1) ->
    @scrollToScreenTop(count)

  scrollToScreenTop: (count) ->
    {row, column} = @editor.getCursorScreenPosition()
    firstScreenRow = @editorView.getFirstVisibleScreenRow() + @scrolloff
    lastScreenRow = @editorView.getLastVisibleScreenRow() - @scrolloff - 1
    lastBufferRow = @editor.getLastBufferRow()
    destRow = lastScreenRow + row - firstScreenRow - @scrolloff
    if destRow < 0
      destRow = 0
    else if destRow > lastBufferRow
      destRow = lastBufferRow
    @editorView.scrollToScreenPosition([destRow, 0])

class ScrollToScreenBottom extends Scroll
  execute: (count=1) ->
    @scrollToScreenBottom(count)

  scrollToScreenBottom: (count) ->
    {row, column} = @editor.getCursorScreenPosition()
    firstScreenRow = @editorView.getFirstVisibleScreenRow() + @scrolloff
    lastScreenRow = @editorView.getLastVisibleScreenRow() - @scrolloff - 1
    lastBufferRow = @editor.getLastBufferRow()
    destRow = row + firstScreenRow - lastScreenRow + @scrolloff
    if destRow < 0
      destRow = 0
    else if destRow > lastBufferRow
      destRow = lastBufferRow
    @editorView.scrollToScreenPosition([destRow, 0])

module.exports = { ScrollDown, ScrollUp, ScrollToScreenMiddle, ScrollToScreenTop, ScrollToScreenBottom }
