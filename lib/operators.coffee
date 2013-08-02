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
    @operatorToRepeat.execute(@count)

  select: ->
    @operatorToRepeat.select(@count)

class RegisterPrefix
  complete: null
  operator: null
  name: null

  constructor: (@name) ->
    @complete = false

  isComplete: -> @complete

  compose: (@operator) ->
    @operator.register = @name if @operator.register?
    @complete = true

  execute: (count=1) ->
    @operator.execute(count)

  select: (count=1) ->
    @operator.select(count)

class Delete
  motion: null
  complete: null

  constructor: (@editor) ->
    @complete = false

  isComplete: -> @complete

  execute: (count=1) ->
    _.times count, =>
      if _.last(@motion.select())
        @editor.getSelection().delete()

    if @motion.isLinewise()
      @editor.setCursorScreenPosition([@editor.getCursor().getScreenRow(), 0])

  compose: (motion) ->
    if not motion.select
      throw new OperatorError("Delete must compose with a motion")

    @motion = motion
    @complete = true

class Yank
  motion: null
  complete: null
  register: null

  constructor: (@editor, @vimState) ->
    @complete = false
    @register ?= '"'

  isComplete: -> @complete

  execute: (count=1) ->
    text = ""

    _.times count, =>
      if _.last(@motion.select())
        text += @editor.getSelection().getText()

    @vimState.setRegister(@register, text)

  compose: (motion) ->
    if not motion.select
      throw new OperatorError("Yank must compose with a motion")

    @motion = motion
    @complete = true

class Put
  motion: null
  direction: null
  register: null

  constructor: (@editor, @vimState, {@direction}={}) ->
    @direction ?= 'after'
    @register ?= '"'

  isComplete: -> true

  execute: (count=1) ->
    text = @vimState.getRegister(@register)

    _.times count, =>
      switch @direction
        when 'before'
          throw new OperatorError("Not Implemented")
        when 'after'
          @editor.insertText(text)

  compose: (register) ->
    throw new OperatorError("Not Implemented")

module.exports = { NumericPrefix, RegisterPrefix, Delete, OperatorError, Yank, Put }
