VimCommandModeInputView = require './vim-command-mode-input-view'
{Point, Range} = require 'atom'

module.exports =

# This is the view model for a Mark Motion. It is an implementation
# detail of the same, and is tested via the use of the `mark` keybindings
# in motions-spec.coffee.
class MoveToMarkViewModel
  constructor: (@moveToMarkOperator) ->
    @editorView = @moveToMarkOperator.editorView
    @vimState   = @moveToMarkOperator.state
    @editor     = @moveToMarkOperator.editor

    @view = new VimCommandModeInputView(@, class: 'move-to-mark', hidden: true, singleChar: true)
    @editorView.editor.commandModeInputView = @view

  confirm: (view) ->
    @char = @view.value
    @editorView.trigger('vim-mode:move-to-mark-complete')

  select: (requireEOL) ->
    markPosition = @vimState.getMark(@char)
    return unless markPosition?
    currentPosition = @editor.getCursorBufferPosition()
    selectionRange = null
    if currentPosition.isGreaterThan(markPosition)
      if @moveToMarkOperator.linewise
        currentPosition = @editor.clipBufferPosition([currentPosition.row, Infinity])
        markPosition = new Point(markPosition.row, 0)
      selectionRange = new Range(markPosition, currentPosition)
    else
      if @moveToMarkOperator.linewise
        markPosition = @editor.clipBufferPosition([markPosition.row, Infinity])
        currentPosition = new Point(currentPosition.row, 0)
      selectionRange = new Range(currentPosition, markPosition)
    @editor.setSelectedBufferRange(selectionRange, requireEOL: requireEOL)

  execute: ->
    markPosition = @vimState.getMark(@char)
    @editor.setCursorBufferPosition(markPosition) if markPosition?
