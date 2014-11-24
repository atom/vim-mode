class FocusAction
  isComplete: -> true
  isRecordable: -> false

  paneContainer: ->
    atom.views.getView(atom.workspace.paneContainer)

  focusCursor: ->
    editor = atom.workspace.getActiveTextEditor()
    editor?.scrollToCursorPosition()

class FocusPaneViewOnLeft extends FocusAction
  execute: ->
    @paneContainer().focusPaneViewOnLeft()
    @focusCursor()

class FocusPaneViewOnRight extends FocusAction
  execute: ->
    @paneContainer().focusPaneViewOnRight()
    @focusCursor()

class FocusPaneViewAbove extends FocusAction
  execute: ->
    @paneContainer().focusPaneViewAbove()
    @focusCursor()

class FocusPaneViewBelow extends FocusAction
  execute: ->
    @paneContainer().focusPaneViewBelow()
    @focusCursor()

class FocusPreviousPaneView extends FocusAction
  execute: ->
    atom.workspace.activatePreviousPane()
    @focusCursor()

module.exports = { FocusPaneViewOnLeft, FocusPaneViewOnRight,
  FocusPaneViewAbove, FocusPaneViewBelow, FocusPreviousPaneView }
