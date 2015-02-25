{MotionWithInput} = require './general-motions'
{ViewModel} = require '../view-models/view-model'
{Point, Range} = require 'atom'

class Find extends MotionWithInput
  constructor: (@editor, @vimState) ->
    super(@editor, @vimState)
    @vimState.currentFind = @
    @viewModel = new ViewModel(@, class: 'find', singleChar: true, hidden: true)
    @backwards = false
    @repeatReversed = false
    @offset = 0
    @repeated = false

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
    @backwards = !@backwards
    @

  moveCursor: (cursor, count=1) ->
    if (match = @match(cursor, count))?
      cursor.setBufferPosition(match)

  repeat: (opts={}) ->
    opts.reverse = !!opts.reverse
    @repeated = true
    if opts.reverse isnt @repeatReversed
      @reverse()
      @repeatReversed = opts.reverse
    @

class Till extends Find
  constructor: (@editor, @vimState) ->
    super(@editor, @vimState)
    @offset = 1

module.exports = {Find, Till}
