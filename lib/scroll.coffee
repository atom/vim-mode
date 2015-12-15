class Scroll
  isComplete: -> true
  isRecordable: -> false
  constructor: (@editorElement) ->
    @scrolloff = 2 # atom default
    @editor = @editorElement.getModel()
    @rows =
      first: @editorElement.getFirstVisibleScreenRow()
      last: @editorElement.getLastVisibleScreenRow()
      final: @editor.getLastScreenRow()

class ScrollDown extends Scroll
  execute: (count=1) ->
    oldFirstRow = @editor.getFirstVisibleScreenRow()
    @editor.setFirstVisibleScreenRow(oldFirstRow + count)
    newFirstRow = @editor.getFirstVisibleScreenRow()

    for cursor in @editor.getCursors()
      position = cursor.getScreenPosition()
      if position.row <= newFirstRow + @scrolloff
        cursor.setScreenPosition([position.row + newFirstRow - oldFirstRow, position.column], autoscroll: false)

    # TODO: remove
    # This is a workaround for a bug fixed in atom/atom#10062
    @editorElement.component.updateSync()

    return

class ScrollUp extends Scroll
  execute: (count=1) ->
    oldFirstRow = @editor.getFirstVisibleScreenRow()
    oldLastRow = @editor.getLastVisibleScreenRow()
    @editor.setFirstVisibleScreenRow(oldFirstRow - count)
    newLastRow = @editor.getLastVisibleScreenRow()

    for cursor in @editor.getCursors()
      position = cursor.getScreenPosition()
      if position.row >= newLastRow - @scrolloff
        cursor.setScreenPosition([position.row - (oldLastRow - newLastRow), position.column], autoscroll: false)

    # TODO: remove
    # This is a workaround for a bug fixed in atom/atom#10062
    @editorElement.component.updateSync()

    return

class ScrollCursor extends Scroll
  constructor: (@editorElement, @opts={}) ->
    super
    cursor = @editor.getCursorScreenPosition()
    @pixel = @editorElement.pixelPositionForScreenPosition(cursor).top

class ScrollCursorToTop extends ScrollCursor
  execute: ->
    @moveToFirstNonBlank() unless @opts.leaveCursor
    @scrollUp()

  scrollUp: ->
    return if @rows.last is @rows.final
    @pixel -= (@editor.getLineHeightInPixels() * @scrolloff)
    @editorElement.setScrollTop(@pixel)

  moveToFirstNonBlank: ->
    @editor.moveToFirstCharacterOfLine()

class ScrollCursorToMiddle extends ScrollCursor
  execute: ->
    @moveToFirstNonBlank() unless @opts.leaveCursor
    @scrollMiddle()

  scrollMiddle: ->
    @pixel -= (@editorElement.getHeight() / 2)
    @editorElement.setScrollTop(@pixel)

  moveToFirstNonBlank: ->
    @editor.moveToFirstCharacterOfLine()

class ScrollCursorToBottom extends ScrollCursor
  execute: ->
    @moveToFirstNonBlank() unless @opts.leaveCursor
    @scrollDown()

  scrollDown: ->
    return if @rows.first is 0
    offset = (@editor.getLineHeightInPixels() * (@scrolloff + 1))
    @pixel -= (@editorElement.getHeight() - offset)
    @editorElement.setScrollTop(@pixel)

  moveToFirstNonBlank: ->
    @editor.moveToFirstCharacterOfLine()

class ScrollHorizontal
  isComplete: -> true
  isRecordable: -> false
  constructor: (@editorElement) ->
    @editor = @editorElement.getModel()
    cursorPos = @editor.getCursorScreenPosition()
    @pixel = @editorElement.pixelPositionForScreenPosition(cursorPos).left
    @cursor = @editor.getLastCursor()

  putCursorOnScreen: ->
    @editor.scrollToCursorPosition({center: false})

class ScrollCursorToLeft extends ScrollHorizontal
  execute: ->
    @editorElement.setScrollLeft(@pixel)
    @putCursorOnScreen()

class ScrollCursorToRight extends ScrollHorizontal
  execute: ->
    @editorElement.setScrollRight(@pixel)
    @putCursorOnScreen()

module.exports = {ScrollDown, ScrollUp, ScrollCursorToTop, ScrollCursorToMiddle,
  ScrollCursorToBottom, ScrollCursorToLeft, ScrollCursorToRight}
