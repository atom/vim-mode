_ = require 'underscore'

class OperatorError
  constructor: (@message) ->
    @name = "Operator Error"

class NumericPrefix
  count: null
  complete: null
  operatorToRepeat: null

  constructor: (@count) ->
    @complete = false

  isComplete: -> @complete

  compose: (@operatorToRepeat) ->
    @complete = true
    if @operatorToRepeat.setCount?
      @operatorToRepeat.setCount @count
      @count = 1

  addDigit: (digit) ->
    @count = @count * 10 + digit

  execute: ->
    _.times @count, => @operatorToRepeat.execute()

  select: ->
    _.times @count, => @operatorToRepeat.select()

class Delete
  motion: null
  complete: null

  constructor: (@editor) ->
    @complete = false

  isComplete: -> @complete

  execute: ->
    if @motion
      if @motion.select()
        @editor.getSelection().delete()
    else
      @editor.getBuffer().deleteRow(@editor.getCursor().getBufferRow())
      @editor.setCursorScreenPosition([@editor.getCursor().getScreenRow(), 0])

  compose: (motion) ->
    if not motion.select
      throw new OperatorError("Delete must compose with a motion")

    @motion = motion
    @complete = true

class Yank
  motion: null
  complete: null

  constructor: (@editor, @vimState) ->
    @complete = false

  isComplete: -> @complete

  execute: ->
    if @motion
      if @motion.select()
        text = @editor.getSelection().getText()
    else
      buffer = @editor.getBuffer()
      text = buffer.lineForRow(@editor.getCursor().getBufferRow())
      text += buffer.lineEndingForRow(@editor.getCursor().getBufferRow())
      @editor.setCursorScreenPosition([@editor.getCursor().getScreenRow(), 0])

    @vimState.setRegister('"', text)

  compose: (motion) ->
    if not motion.select
      throw new OperatorError("Yank must compose with a motion")

    @motion = motion
    @complete = true

class Put
  motion: null
  direction: null

  constructor: (@editor, @vimState, {@direction}={}) ->
    @direction ?= 'after'

  isComplete: -> true

  execute: ->
    text = @vimState.getRegister('"')
    switch @direction
      when 'before'
        throw new OperatorError("Not Implemented")
      when 'after'
        @editor.insertText(text)

  compose: (register) ->
    throw new OperatorError("Not Implemented")

module.exports = { NumericPrefix, Delete, OperatorError, Yank, Put }
