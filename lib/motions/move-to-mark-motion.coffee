{MotionWithInput} = require './general-motions'
{ViewModel} = require '../view-models/view-model'
{Point, Range} = require 'atom'

module.exports =
class MoveToMark extends MotionWithInput
  constructor: (@editorView, @vimState, @linewise=true) ->
    super(@editorView, @vimState)
    @viewModel = new ViewModel(@, class: 'move-to-mark', singleChar: true, hidden: true)

  isLinewise: -> @linewise

  execute: ->
    markPosition = @vimState.getMark(@input.characters)

    if @input.characters == '`' # double '`' pressed
      markPosition ?= [0, 0] # if markPosition not set, go to the beginning of the file
      @vimState.setMark('`', @editorView.editor.getCursorBufferPosition())

    @editor.setCursorBufferPosition(markPosition) if markPosition?
    if @linewise
      @editorView.trigger 'vim-mode:move-to-first-character-of-line'

  select: (count=1, {requireEOL}={}) ->
    markPosition = @vimState.getMark(@input.characters)
    return [false] unless markPosition?
    currentPosition = @editor.getCursorBufferPosition()
    selectionRange = null
    if currentPosition.isGreaterThan(markPosition)
      if @linewise
        currentPosition = @editor.clipBufferPosition([currentPosition.row, Infinity])
        markPosition = new Point(markPosition.row, 0)
      selectionRange = new Range(markPosition, currentPosition)
    else
      if @linewise
        markPosition = @editor.clipBufferPosition([markPosition.row, Infinity])
        currentPosition = new Point(currentPosition.row, 0)
      selectionRange = new Range(currentPosition, markPosition)
    @editor.setSelectedBufferRange(selectionRange, requireEOL: requireEOL)
    [true]
