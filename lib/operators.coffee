_ = require 'underscore'

class OperatorError
  constructor: (@message) ->
    @name = "Operator Error"

#
# Used to track the number of times either a motion or operator should
# be repeated.
#
class NumericPrefix
  count: null
  complete: null
  composedOperator: null

  constructor: (@count) ->
    @complete = false

  isComplete: -> @complete

  # Public: Marks this as complete as soon as another operator is available.
  #
  # operatorToRepeat - The next motion or operator.
  #
  # Returns nothing.
  compose: (@composedOperator) ->
    @complete = true

  # Public: Tracks an additional digit for this NumericPrefix.
  #
  # digit - A single digit, 0-9
  #
  # Returns nothing.
  addDigit: (digit) ->
    @count = @count * 10 + digit

  # Public: Executes the composed operator or motion.
  #
  # Returns nothing.
  execute: ->
    @composedOperator.execute(@count)

  # Public: Selects using the composed operator or motion.
  #
  # Returns an array of whether the selections were successful.
  select: ->
    @composedOperator.select(@count)

#
# Used to track which register the following operator should operate on.
#
class RegisterPrefix
  complete: null
  composedOperator: null
  name: null

  constructor: (@name) ->
    @complete = false

  isComplete: -> @complete

  # Public: Marks this as complete and sets the operator's register if
  # it accepts it.
  #
  # composedOperator - The next operator.
  #
  # Returns nothing.
  compose: (@composedOperator) ->
    @composedOperator.register = @name if @composedOperator.register?
    @complete = true

  # Public: Executes the composed operator.
  #
  # count - The number of times to repeat.
  #
  # Returns nothing.
  execute: (count=1) ->
    @composedOperator.execute(count)

  # Public: Selects using the composed operator.
  #
  # count - The number of times to repeat.
  #
  # Returns an array of whether the selections were successful.
  select: (count=1) ->
    @composedOperator.select(count)

#
# It deletes everything selected by the following motion.
#
class Delete
  motion: null
  complete: null
  vimState: null

  constructor: (@editor, @vimState, @motion) ->
    @complete = false

  isComplete: -> @complete

  # Public: Deletes the text selected by the given motion.
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: (count=1) ->
    cursor = @editor.getCursor()

    _.times count, =>
      if _.last(@motion.select())
        @editor.getSelection().delete()

      @editor.moveCursorLeft() if cursor.isAtEndOfLine()

    if @motion.isLinewise?()
      @editor.setCursorScreenPosition([@editor.getCursor().getScreenRow(), 0])

  # Public: Marks this as complete and saves the motion.
  #
  # motion - The motion used to select what to delete.
  #
  # Returns nothing.
  compose: (motion) ->
    if not motion.select
      throw new OperatorError("Delete must compose with a motion")

    @motion = motion
    @complete = true

#
# It changes everything selected by the following motion.
#
class Change
  motion: null
  complete: null
  vimState: null

  constructor: (@editor, @vimState) ->
    @complete = false

  isComplete: -> @complete

  # Public: Changes the text selected by the given motion.
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: (count=1) ->
    operator = new Delete(@editor, @vimState, @motion)
    operator.execute(count)

    @vimState.activateInsertMode()

  # Public: Marks this as complete and saves the motion.
  #
  # motion - The motion used to select what to change.
  #
  # Returns nothing.
  compose: (motion) ->
    if not motion.select
      throw new OperatorError("Change must compose with a motion")

    @motion = motion
    @complete = true

#
# It copies everything selected by the following motion.
#
class Yank
  motion: null
  complete: null
  register: null
  vimState: null

  constructor: (@editor, @vimState) ->
    @complete = false
    @register ?= '"'

  isComplete: -> @complete

  # Public: Copies the text selected by the given motion.
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: (count=1) ->
    text = ""
    type = if @motion.isLinewise then 'linewise' else 'character'

    originalPosition = @editor.getCursorScreenPosition()
    _.times count, =>
      if _.last(@motion.select())
        text += @editor.getSelection().getText()

    @vimState.setRegister(@register, {text, type})

    if @motion.isLinewise?()
      @editor.setCursorScreenPosition(originalPosition)
    else
      @editor.clearSelections()

  # Public: Marks this as complete and saves the motion.
  #
  # motion - The motion used to select what to copy.
  #
  # Returns nothing.
  compose: (motion) ->
    if not motion.select
      throw new OperatorError("Yank must compose with a motion")

    @motion = motion
    @complete = true

#
# It indents everything selected by the following motion.
#
class Indent
  motion: null
  complete: null

  constructor: (@editor) ->
    @complete = false

  isComplete: -> @complete

  # Public: Indents the text selected by the given motion.
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: (count=1) ->
    row = @editor.getCursorScreenRow()

    _.times count, =>
      if _.last(@motion.select())
        @editor.indentSelectedRows()

    @editor.setCursorScreenPosition([row, 0])
    @editor.moveCursorToFirstCharacterOfLine()

  # Public: Marks this as complete and saves the motion.
  #
  # motion - The motion used to select what to delete.
  #
  # Returns nothing.
  compose: (motion) ->
    if not motion.select
      throw new OperatorError("Indent must compose with a motion")

    @motion = motion
    @complete = true

#
# It indents everything selected by the following motion.
#
class Outdent
  motion: null
  complete: null

  constructor: (@editor) ->
    @complete = false

  isComplete: -> @complete

  # Public: Indents the text selected by the given motion.
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: (count=1) ->
    row = @editor.getCursorScreenRow()

    _.times count, =>
      if _.last(@motion.select())
        @editor.outdentSelectedRows()

    @editor.setCursorScreenPosition([row, 0])
    @editor.moveCursorToFirstCharacterOfLine()

  # Public: Marks this as complete and saves the motion.
  #
  # motion - The motion used to select what to delete.
  #
  # Returns nothing.
  compose: (motion) ->
    if not motion.select
      throw new OperatorError("Indent must compose with a motion")

    @motion = motion
    @complete = true

#
# It pastes everything contained within the specifed register
#
class Put
  motion: null
  direction: null
  register: null

  constructor: (@editor, @vimState, {@location}={}) ->
    @direction ?= 'after'
    @register ?= '"'

  isComplete: -> true

  # Public: Pastes the text in the given register.
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: (count=1) ->
    {text, type} = @vimState.getRegister(@register) || {}
    return unless text

    _.times count, =>
      if type == 'linewise' and @location == 'after'
        @editor.moveCursorDown()
      else if @location == 'after'
        @editor.moveCursorRight()

      @editor.moveCursorToBeginningOfLine() if type == 'linewise'
      @editor.insertText(text)

      if type == 'linewise'
        @editor.moveCursorUp()
        @editor.moveCursorToFirstCharacterOfLine()

  # Public: Not implemented.
  #
  # Returns nothing.
  compose: (register) ->
    throw new OperatorError("Not Implemented")

#
# It combines the current line with the following line.
#
class Join
  constructor: (@editor) ->

  isComplete: -> true

  # Public: Combines the current with the following lines
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: (count=1) ->
    _.times count, =>
      @editor.joinLine()

  # Public: Not implemented.
  #
  # Returns nothing.
  compose: (register) ->
    throw new OperatorError("Not Implemented")

module.exports = { NumericPrefix, RegisterPrefix, Delete, OperatorError, Yank,
  Put, Join, Indent, Outdent, Change }
