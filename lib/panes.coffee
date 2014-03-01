class FocusAction
  constructor: ->
  isComplete: -> true
  isRecordable: -> false

  focusCursor: ->
    editor = atom.workspaceView.getActivePaneItem()
    editorView = atom.workspaceView.getActiveView()
    if editor? and editorView?
      cursorPosition = editor.getCursorBufferPosition()
      editorView.scrollToBufferPosition(cursorPosition)

class FocusPaneViewOnLeft extends FocusAction
  execute: ->
    atom.workspaceView.focusPaneViewOnLeft()
    @focusCursor()

class FocusPaneViewOnRight extends FocusAction
  execute: ->
    atom.workspaceView.focusPaneViewOnRight()
    @focusCursor()

class FocusPaneViewAbove extends FocusAction
  execute: ->
    atom.workspaceView.focusPaneViewAbove()
    @focusCursor()

class FocusPaneViewBelow extends FocusAction
  execute: ->
    atom.workspaceView.focusPaneViewBelow()
    @focusCursor()

class FocusPreviousPaneView extends FocusAction
  execute: ->
    atom.workspaceView.focusPreviousPaneView()
    @focusCursor()

module.exports = { FocusPaneViewOnLeft, FocusPaneViewOnRight,
  FocusPaneViewAbove, FocusPaneViewBelow, FocusPreviousPaneView }
