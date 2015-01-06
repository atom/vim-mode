class Prefix
  complete: null
  composedObject: null

  isComplete: -> @complete

  isRecordable: -> @composedObject.isRecordable()

  # Public: Marks this as complete upon receiving an object to compose with.
  #
  # composedObject - The next motion or operator.
  #
  # Returns nothing.
  compose: (@composedObject) ->
    @complete = true

  # Public: Executes the composed operator or motion.
  #
  # Returns nothing.
  execute: ->
    @composedObject.execute?(@count)

  # Public: Selects using the composed motion.
  #
  # Returns an array of booleans representing whether each selections' success.
  select: ->
    @composedObject.select?(@count)

  isLinewise: ->
    @composedObject.isLinewise()

#
# Used to track the number of times either a motion or operator should
# be repeated.
#
class Repeat extends Prefix
  count: null

  # count - The initial digit of the repeat sequence.
  constructor: (@count) -> @complete = false

  # Public: Adds an additional digit to this repeat sequence.
  #
  # digit - A single digit, 0-9.
  #
  # Returns nothing.
  addDigit: (digit) ->
    @count = @count * 10 + digit

#
# Used to track which register the following operator should operate on.
#
class Register extends Prefix
  name: null

  # name - The single character name of the desired register
  constructor: (@name) -> @complete = false

  # Public: Marks as complete and sets the operator's register if it accepts it.
  #
  # composedOperator - The operator this register pertains to.
  #
  # Returns nothing.
  compose: (composedObject) ->
    super(composedObject)
    composedObject.register = @name if composedObject.register?

module.exports = { Repeat, Register}
