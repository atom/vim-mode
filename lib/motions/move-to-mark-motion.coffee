{MotionWithInput, MoveToFirstCharacterOfLine} = require './general-motions'
{ViewModel} = require '../view-models/view-model'
{Point, Range} = require 'atom'

module.exports =
class MoveToMark extends MotionWithInput
  operatesInclusively: false

  constructor: (@editor, @vimState, @linewise=true) ->
    super(@editor, @vimState)
    @operatesLinewise = @linewise
    @viewModel = new ViewModel(@, class: 'move-to-mark', singleChar: true, hidden: true)

  isLinewise: -> @linewise

  moveCursor: (cursor, count=1) ->
    markPosition = @vimState.getMark(@input.characters)

    if @input.characters is '`' # double '`' pressed
      markPosition ?= [0, 0] # if markPosition not set, go to the beginning of the file
      @vimState.setMark('`', cursor.getBufferPosition())

    cursor.setBufferPosition(markPosition) if markPosition?
    if @linewise
      cursor.moveToFirstCharacterOfLine()
