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

class MovePane
  isComplete: -> true
  isRecordable: -> false
  constructor: (@orientation, @pos) ->

  execute: ->
    rootContainer = atom.workspace.paneContainer
    activePane = atom.workspace.getActivePane()
    # nothing to do if there's only one pane
    return if activePane.parent is rootContainer

    # hack: PaneAxis is not in Atom API
    PaneAxis = activePane.parent.constructor

    activePane.parent.removeChild activePane

    rootPane = rootContainer.root
    if rootPane.orientation isnt @orientation
      newPane = new PaneAxis
        container: rootContainer
        orientation: @orientation
        children: [rootPane]
      rootContainer.replaceChild(rootPane, newPane)
      rootPane = newPane

    rootPane.addChild activePane, switch @pos
      when 'begin' then 0
      when 'end' then null

    activePane.activate()
    activePane.getActiveItem()?.scrollToCursorPosition()



module.exports = { FocusPaneViewOnLeft, FocusPaneViewOnRight,
  FocusPaneViewAbove, FocusPaneViewBelow,
  FocusPreviousPaneView,
  MovePane }
