{Point, Range} = require 'atom'
ViewModel = require './view-model'

module.exports =
class MoveToMarkViewModel extends ViewModel
  constructor: (@moveToMarkOperator) ->
    super(@moveToMarkOperator, class: 'move-to-mark', singleChar: true, hidden: true)
    @editor = @moveToMarkOperator.editor

  select: (character, requireEOL) ->
    markPosition = @vimState.getMark(character)
    return [false] unless markPosition?
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
    [true]

  execute: (character) ->
    markPosition = @vimState.getMark(character)
    @editor.setCursorBufferPosition(markPosition) if markPosition?
    if @moveToMarkOperator.linewise
      @editorView.trigger 'vim-mode:move-to-first-character-of-line'
