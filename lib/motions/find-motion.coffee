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

  match: (count) ->
    currentPosition = @editor.getCursorBufferPosition()
    line = @editor.lineTextForBufferRow(currentPosition.row)
    if @backwards
      index = currentPosition.column
      for i in [0..count-1]
        index = line.lastIndexOf(@input.characters, index-1)
      if index != -1
        point = new Point(currentPosition.row, index+@offset)
        return {} =
          point: point
          range: new Range(point, currentPosition)
    else
      index = currentPosition.column
      for i in [0..count-1]
        index = line.indexOf(@input.characters, index+1)
      if index != -1
        point = new Point(currentPosition.row, index-@offset)
        return {} =
          point: point
          range: new Range(currentPosition, point.add([0,1]))

  reverse: ->
    @backwards = !@backwards
    @

  execute: (count=1) ->
    if (match = @match(count))?
      @editor.setCursorBufferPosition(match.point)

  select: (count=1, {requireEOL}={}) ->
    if (match = @match(count))?
      @editor.setSelectedBufferRange(match.range)
      return [true]
    [false]

  repeat: (opts={}) ->
    opts.reverse = !!opts.reverse
    if opts.reverse isnt @repeatReversed
      @reverse()
      @repeatReversed = opts.reverse
    @

class Till extends Find
  constructor: (@editor, @vimState) ->
    super(@editor, @vimState)
    @offset = 1

module.exports = {Find, Till}
