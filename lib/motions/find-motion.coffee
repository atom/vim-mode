{MotionWithInput} = require './general-motions'
{ViewModel} = require '../view-models/view-model'
{Point, Range} = require 'atom'

class Find extends MotionWithInput
  operatesInclusively: true

  constructor: (@editor, @vimState, opts={}) ->
    super(@editor, @vimState)
    @offset = 0

    if not opts.repeated
      @viewModel = new ViewModel(this, class: 'find', singleChar: true, hidden: true)
      @backwards = false
      @repeated = false
      @vimState.globalVimState.currentFind = this

    else
      @repeated = true

      orig = @vimState.globalVimState.currentFind
      @backwards = orig.backwards
      @complete = orig.complete
      @input = orig.input

      @reverse() if opts.reverse

  match: (cursor, count) ->
    currentPosition = cursor.getBufferPosition()
    line = @editor.lineTextForBufferRow(currentPosition.row)
    if @backwards
      index = currentPosition.column
      for i in [0..count-1]
        return if index <= 0 # we can't move backwards any further, quick return
        index = line.lastIndexOf(@input.characters, index-1-(@offset*@repeated))
      if index >= 0
        new Point(currentPosition.row, index + @offset)
    else
      index = currentPosition.column
      for i in [0..count-1]
        index = line.indexOf(@input.characters, index+1+(@offset*@repeated))
        return if index < 0 # no match found
      if index >= 0
        new Point(currentPosition.row, index - @offset)

  reverse: ->
    @backwards = not @backwards
    this

  moveCursor: (cursor, count=1) ->
    if (match = @match(cursor, count))?
      cursor.setBufferPosition(match)

class Till extends Find
  constructor: (@editor, @vimState, opts={}) ->
    super(@editor, @vimState, opts)
    @offset = 1

  match: ->
    @selectAtLeastOne = false
    retval = super
    if retval? and not @backwards
      @selectAtLeastOne = true
    retval

  moveSelectionInclusively: (selection, count, options) ->
    super
    if selection.isEmpty() and @selectAtLeastOne
      selection.modifySelection ->
        selection.cursor.moveRight()

module.exports = {Find, Till}
